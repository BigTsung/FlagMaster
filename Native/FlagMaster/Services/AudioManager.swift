import AVFoundation

enum AudioTrack: String, Sendable {
    case home = "music_home"
    case game = "music_game"
}

enum SoundEffect: String, Sendable {
    case tap = "sfx_tap"
    case correct = "sfx_correct"
    case wrong = "sfx_wrong"
    case complete = "sfx_complete"
}

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var musicPlayer: AVAudioPlayer?
    private var fadingPlayer: AVAudioPlayer?
    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var currentTrack: AudioTrack?
    private var musicVolume: VolumeLevel = .medium
    private var soundVolume: VolumeLevel = .high
    private var isDucked = false
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
        guard currentTrack != track else {
            updateVolumes()
            return
        }
        guard let url = resourceURL(named: track.rawValue, extension: "m4a"),
              let next = try? AVAudioPlayer(contentsOf: url) else { return }

        fadingPlayer?.stop()
        fadingPlayer = musicPlayer
        fadingPlayer?.setVolume(0, fadeDuration: 0.8)

        currentTrack = track
        musicPlayer = next
        next.numberOfLoops = -1
        next.volume = 0
        next.prepareToPlay()
        guard isAppActive, musicVolume != .off else { return }
        next.play()
        next.setVolume(targetMusicVolume, fadeDuration: 0.8)
    }

    func play(_ effect: SoundEffect) {
        guard soundVolume != .off else { return }
        if effectPlayers[effect] == nil { effectPlayers[effect] = makeEffectPlayer(effect) }
        guard let player = effectPlayers[effect] else { return }
        player.currentTime = 0
        player.volume = targetEffectVolume(effect)
        player.play()
    }

    func setDucked(_ ducked: Bool) {
        isDucked = ducked
        musicPlayer?.setVolume(targetMusicVolume, fadeDuration: 0.35)
    }

    func setAppActive(_ active: Bool) {
        isAppActive = active
        if active {
            guard musicVolume != .off else { return }
            if musicPlayer?.isPlaying == false { musicPlayer?.play() }
            musicPlayer?.setVolume(targetMusicVolume, fadeDuration: 0.35)
        } else {
            musicPlayer?.pause()
            fadingPlayer?.stop()
        }
    }

    private var targetMusicVolume: Float {
        musicVolume.value * (isDucked ? 0.12 : 0.34)
    }

    private func targetEffectVolume(_ effect: SoundEffect) -> Float {
        let gain: Float = effect == .wrong ? 0.55 : effect == .tap ? 0.5 : 0.72
        return soundVolume.value * gain
    }

    private func updateVolumes() {
        musicPlayer?.setVolume(targetMusicVolume, fadeDuration: 0.25)
        for (effect, player) in effectPlayers { player.volume = targetEffectVolume(effect) }
        if musicVolume == .off {
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
        for effect in [SoundEffect.tap, .correct, .wrong, .complete] {
            effectPlayers[effect] = makeEffectPlayer(effect)
        }
    }

    private func makeEffectPlayer(_ effect: SoundEffect) -> AVAudioPlayer? {
        guard let url = resourceURL(named: effect.rawValue, extension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }

    private func resourceURL(named name: String, extension fileExtension: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Audio")
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension)
    }
}
