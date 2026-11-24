import AVFoundation

enum AudioTrack: String, Sendable {
    case home = "music_home"
    case game = "music_game"
    case learning = "music_learning"
    case speedRound = "music_speed_round"
    case twoLives = "music_two_lives"
    case review = "music_review"
    case region = "music_region"
    case comparison = "music_comparison"
    case cards = "music_cards"
}

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var musicPlayer: AVAudioPlayer?
    private static let crossfadeDuration = 0.8

    private var fadingPlayers: [AudioTrack: AVAudioPlayer] = [:]
    private var fadeCleanup: Task<Void, Never>?
    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var currentTrack: AudioTrack?
    private var musicVolume: VolumeLevel = .medium
    private var soundVolume: VolumeLevel = .high
    private var isAppActive = true

    private init() {}

    func configure(music: VolumeLevel, sound: VolumeLevel) {
        musicVolume = music
        soundVolume = sound
        configureSession()
        preloadEffects()
        updateVolumes()
    }

    func updateMusicVolume(_ level: VolumeLevel) {
        musicVolume = level
        updateVolumes()
    }

    func updateSoundVolume(_ level: VolumeLevel) {
        soundVolume = level
        updateVolumes()
    }

    func playMusic(_ track: AudioTrack) {
        guard currentTrack != track else { return }

        let next: AVAudioPlayer
        if let fading = fadingPlayers[track] {
            next = fading
        } else {
            let localURL = Bundle.main.url(forResource: track.rawValue, withExtension: "m4a", subdirectory: "Audio/LocalMusic")
            guard let url = localURL ?? resourceURL(named: track.rawValue, extension: "m4a"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { return }
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            next = player
        }

        let shouldPlay = isAppActive && musicVolume != .off
        if shouldPlay, !next.isPlaying, !next.play() { return }

        fadingPlayers.removeValue(forKey: track)
        if let currentTrack, let musicPlayer, musicPlayer.isPlaying {
            fadingPlayers[currentTrack] = musicPlayer
        }
        currentTrack = track
        musicPlayer = next
        guard shouldPlay else { return }

        next.setVolume(targetMusicVolume, fadeDuration: Self.crossfadeDuration)
        fadeCleanup?.cancel()
        guard !fadingPlayers.isEmpty else { return }
        for player in fadingPlayers.values {
            player.setVolume(0, fadeDuration: Self.crossfadeDuration)
        }
        fadeCleanup = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(Self.crossfadeDuration + 0.05)) } catch { return }
            self?.stopFadingMusic()
        }
    }

    private func stopFadingMusic() {
        fadeCleanup?.cancel()
        fadeCleanup = nil
        for player in fadingPlayers.values { player.stop() }
        fadingPlayers.removeAll()
    }

    func play(_ effect: SoundEffect) {
        guard isAppActive, soundVolume != .off else { return }
        // Important feedback interrupts incidental sounds, never the reverse.
        guard !effectPlayers.contains(where: { $0.value.isPlaying && $0.key.priority > effect.priority }) else { return }
        for (_, player) in effectPlayers where player.isPlaying { player.stop() }
        if effectPlayers[effect] == nil { effectPlayers[effect] = makeEffectPlayer(effect) }
        guard let player = effectPlayers[effect] else { return }
        player.currentTime = 0
        player.volume = targetEffectVolume(effect)
        player.play()
    }

    func stopEffects() {
        for player in effectPlayers.values { player.stop(); player.currentTime = 0 }
    }

    func setAppActive(_ active: Bool) {
        isAppActive = active
        if active {
            guard musicVolume != .off else { return }
            if musicPlayer?.isPlaying == false { musicPlayer?.play() }
            musicPlayer?.setVolume(targetMusicVolume, fadeDuration: 0.35)
        } else {
            musicPlayer?.pause()
            stopFadingMusic()
            stopEffects()
        }
    }

    private var isDucked = false

    private var targetMusicVolume: Float {
        musicVolume.value * (isDucked ? 0.08 : 0.34)
    }

    func duckMusic(_ ducked: Bool) {
        guard isDucked != ducked else { return }
        isDucked = ducked
        musicPlayer?.setVolume(targetMusicVolume, fadeDuration: 0.2)
    }

    private func targetEffectVolume(_ effect: SoundEffect) -> Float {
        let gain: Float
        switch effect {
        case .tap: gain = 0.42
        case .countdown: gain = 0.36
        case .wrong, .timeout: gain = 0.55
        case .end, .gameOver: gain = 0.60
        case .correct, .complete: gain = 0.72
        }
        return soundVolume.value * gain
    }

    private func updateVolumes() {
        musicPlayer?.setVolume(targetMusicVolume, fadeDuration: 0.25)
        for (effect, player) in effectPlayers { player.volume = targetEffectVolume(effect) }
        if soundVolume == .off { stopEffects() }
        if musicVolume == .off {
            stopFadingMusic()
            musicPlayer?.pause()
        } else if isAppActive, currentTrack != nil, musicPlayer?.isPlaying == false {
            musicPlayer?.play()
        }
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func preloadEffects() {
        guard effectPlayers.isEmpty else { return }
        for effect in SoundEffect.allCases {
            effectPlayers[effect] = makeEffectPlayer(effect)
        }
    }

    private func makeEffectPlayer(_ effect: SoundEffect) -> AVAudioPlayer? {
        let localURL = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: "Audio/LocalEffects")
        guard let url = localURL ?? resourceURL(named: effect.rawValue, extension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }

    private func resourceURL(named name: String, extension fileExtension: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Audio")
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension)
    }
}

/// Reads country names and notes aloud. Music is ducked while a voice is speaking.
@MainActor
final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()
    /// Identifies what is currently being read, so the matching button can show its state.
    @Published private(set) var speakingID: String?
    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    static func voiceLanguage(_ language: AppLanguage) -> String {
        switch language {
        case .english: "en-US"
        case .traditionalChinese: "zh-TW"
        case .japanese: "ja-JP"
        case .korean: "ko-KR"
        }
    }

    /// Tapping the same item again stops it; tapping another item replaces it.
    func toggle(_ text: String, language: AppLanguage, id: String) {
        let wasSpeaking = speakingID == id
        stop()
        guard !wasSpeaking, !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Self.voiceLanguage(language))
        // Slightly slower than default so children can follow along.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        speakingID = id
        AudioManager.shared.duckMusic(true)
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        finished()
    }

    private func finished() {
        guard speakingID != nil else { return }
        speakingID = nil
        AudioManager.shared.duckMusic(false)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in if !self.synthesizer.isSpeaking { self.finished() } }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in if !self.synthesizer.isSpeaking { self.finished() } }
    }
}
