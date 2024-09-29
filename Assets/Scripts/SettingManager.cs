using System.IO;
using UnityEngine;

public class SettingsManager : Singleton<SettingsManager>
{
    private const string MUSIC_VOLUME_KEY = "MusicVolume";
    private const string SFX_VOLUME_KEY = "SFXVolume";
    private string jsonFilePath;

    private void Start()
    {
        // 設置文件路徑
        jsonFilePath = Path.Combine(Application.persistentDataPath, "CountryStats.json");

        // 初始化音量設定
        InitializeVolumeSettings();
    }

    // 音樂音量按鈕邏輯
    public void SetMusicVolumeHigh() => SetMusicVolume(0.85f);
    public void SetMusicVolumeMedium() => SetMusicVolume(0.5f);
    public void SetMusicVolumeLow() => SetMusicVolume(0.25f);
    public void SetMusicVolumeOff() => SetMusicVolume(0f);

    // 音效音量按鈕邏輯
    public void SetSFXVolumeHigh() => SetSFXVolume(0.85f);
    public void SetSFXVolumeMedium() => SetSFXVolume(0.5f);
    public void SetSFXVolumeLow() => SetSFXVolume(0.25f);
    public void SetSFXVolumeOff() => SetSFXVolume(0f);

    // 初始化音量設定，從保存的設置讀取
    private void InitializeVolumeSettings()
    {
        // 預設值為 0.5f
        float musicVolume = PlayerPrefs.GetFloat(MUSIC_VOLUME_KEY, 0.5f);
        float sfxVolume = PlayerPrefs.GetFloat(SFX_VOLUME_KEY, 0.5f);

        // 將音量套用到 AudioManager (你需要自行定義這個管理音效的部分)
        AudioManager.Instance.SetBGMVolume(musicVolume);
        AudioManager.Instance.SetSfxVolume(sfxVolume);
    }

    // 設定音樂音量並保存
    private void SetMusicVolume(float volume)
    {
        AudioManager.Instance.SetBGMVolume(volume);  // 設定音量
        PlayerPrefs.SetFloat(MUSIC_VOLUME_KEY, volume);  // 保存到 PlayerPrefs
        PlayerPrefs.Save();  // 儲存
    }

    // 設定音效音量並保存
    private void SetSFXVolume(float volume)
    {
        AudioManager.Instance.SetSfxVolume(volume);  // 設定音量
        PlayerPrefs.SetFloat(SFX_VOLUME_KEY, volume);  // 保存到 PlayerPrefs
        PlayerPrefs.Save();  // 儲存
    }

    // 清空 review mode 的 JSON 檔案
    public void ClearReviewModeData()
    {
        if (File.Exists(jsonFilePath))
        {
            File.Delete(jsonFilePath);
            Debug.Log("Review mode JSON file has been deleted.");
        }
        else
        {
            Debug.LogWarning("Review mode JSON file does not exist.");
        }
    }
}