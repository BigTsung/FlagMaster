using System.Collections.Generic;
using UnityEngine;

public class AudioManager : Singleton<AudioManager>
{
    [SerializeField] private AudioSource bgmSource; // Audio source for background music
    [SerializeField] private AudioSource sfxSource; // Audio source for sound effects (one-shots)
    [SerializeField] private List<AudioClip> bgmClips; // List of BGM audio clips
    [SerializeField] private List<AudioClip> sfxClips; // List of sound effect clips

    private string currentBGM; // Track the currently playing BGM

    // Play background music (BGM)
    public void PlayBGM(string bgmName)
    {
        if (bgmName == currentBGM) return; // If the same BGM is already playing, do nothing

        AudioClip bgmClip = GetAudioClip(bgmClips, bgmName);
        if (bgmClip != null)
        {
            bgmSource.clip = bgmClip;
            bgmSource.loop = true; // Ensure BGM loops
            bgmSource.Play();
            currentBGM = bgmName; // Set the currently playing BGM
        }
        else
        {
            Debug.LogWarning("BGM clip not found: " + bgmName);
        }
    }

    // Stop the currently playing BGM
    public void StopBGM()
    {
        bgmSource.Stop();
        currentBGM = null; // Clear current BGM
    }

    // Play a one-shot sound effect
    public void PlaySFX(string sfxName)
    {
        AudioClip sfxClip = GetAudioClip(sfxClips, sfxName);
        if (sfxClip != null)
        {
            sfxSource.PlayOneShot(sfxClip);
        }
        else
        {
            Debug.LogWarning("SFX clip not found: " + sfxName);
        }
    }

    // Get audio clip from a list by name
    private AudioClip GetAudioClip(List<AudioClip> clipList, string clipName)
    {
        return clipList.Find(clip => clip.name == clipName);
    }
}