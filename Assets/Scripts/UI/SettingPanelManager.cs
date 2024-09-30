using UnityEngine;
using UnityEngine.UI;
using TMPro;  // 必須引用 TextMeshPro 命名空間
using UnityEngine.Localization;
using UnityEngine.Localization.Settings;
using UnityEngine.Localization.Components;  // 必須引用 LocalizeStringEvent

public class SettingPanelManager : Singleton<SettingPanelManager>
{
    [SerializeField] private string pressedSFX = "ui_menu_button_click_19";
    [SerializeField] private float feedbackDuration = 0.15f;  // 按鈕縮放動畫持續時間
    [SerializeField] private Vector3 pressedScale = new Vector3(0.9f, 0.9f, 0.9f);  // 按鈕按下時的縮放

    public Button musicHighButton;
    public Button musicMediumButton;
    public Button musicLowButton;
    public Button musicOffButton;

    public Button sfxHighButton;
    public Button sfxMediumButton;
    public Button sfxLowButton;
    public Button sfxOffButton;

    public Button languageChineseButton;
    public Button languageEnglishButton;

    public Button cleanReviewModeButton;
    public Button updateButton;

    [SerializeField] private LocalizeStringEvent[] localizedTextElements; // 新增這個變量來控制所有本地化的 UI 文字

    [SerializeField] private Color activeTextColor = Color.white;  // Text color for active button
    [SerializeField] private Color inactiveTextColor = Color.gray; // Text color for inactive buttons

    private void Start()
    {
        // default: hide SettingPanel

        //Initialize button color states
        InitializeUI();

        //Initialize the language settings
        InitializeLanguageSetting();
    }

    public void InitializeUI()
    {
        // Load the saved settings and set button colors accordingly
        float musicVolume = PlayerPrefs.GetFloat("MusicVolume", 0.5f); // Default volume is 0.5
        float sfxVolume = PlayerPrefs.GetFloat("SFXVolume", 0.5f);     // Default volume is 0.5

        // Update button text colors
        UpdateMusicButtonColors(musicVolume);
        UpdateSFXButtonColors(sfxVolume);

        // Update language button colors
        string currentLanguage = PlayerPrefs.GetString("Language", "zh-TW");
        UpdateLanguageButtonColors(currentLanguage);

        InitializeLanguageSetting();
    }

    private void InitializeLanguageSetting()
    {
        // Check previously saved language and set current language
        string currentLanguage = PlayerPrefs.GetString("Language", "zh-TW");
        Locale selectedLocale = LocalizationSettings.AvailableLocales.GetLocale(currentLanguage);
        LocalizationSettings.SelectedLocale = selectedLocale;
        UpdateAllLocalizedTexts();
    }

    // 音樂音量按鈕控制
    public void OnMusicHighButtonPressed()
    {
        PlayButtonFeedback(musicHighButton);
        SettingsManager.Instance.SetMusicVolumeHigh();
        UpdateMusicButtonColors(0.85f);
    }

    public void OnMusicMediumButtonPressed()
    {
        PlayButtonFeedback(musicMediumButton);
        SettingsManager.Instance.SetMusicVolumeMedium();
        UpdateMusicButtonColors(0.5f);
    }

    public void OnMusicLowButtonPressed()
    {
        PlayButtonFeedback(musicLowButton);
        SettingsManager.Instance.SetMusicVolumeLow();
        UpdateMusicButtonColors(0.25f);
    }

    public void OnMusicOffButtonPressed()
    {
        PlayButtonFeedback(musicOffButton);
        SettingsManager.Instance.SetMusicVolumeOff();
        UpdateMusicButtonColors(0f);
    }

    // 音效音量按鈕控制
    public void OnSFXHighButtonPressed()
    {
        PlayButtonFeedback(sfxHighButton);
        SettingsManager.Instance.SetSFXVolumeHigh();
        UpdateSFXButtonColors(0.85f);
    }

    public void OnSFXMediumButtonPressed()
    {
        PlayButtonFeedback(sfxMediumButton);
        SettingsManager.Instance.SetSFXVolumeMedium();
        UpdateSFXButtonColors(0.5f);
    }

    public void OnSFXLowButtonPressed()
    {
        PlayButtonFeedback(sfxLowButton);
        SettingsManager.Instance.SetSFXVolumeLow();
        UpdateSFXButtonColors(0.25f);
    }

    public void OnSFXOffButtonPressed()
    {
        PlayButtonFeedback(sfxOffButton);
        SettingsManager.Instance.SetSFXVolumeOff();
        UpdateSFXButtonColors(0f);
    }

    // 語言按鈕控制
    public void OnLanguageChineseButtonPressed()
    {
        PlayButtonFeedback(languageChineseButton);
        SetLanguage("zh-TW");
        UpdateLanguageButtonColors("zh-TW");
    }

    public void OnLanguageEnglishButtonPressed()
    {
        PlayButtonFeedback(languageEnglishButton);
        SetLanguage("en");
        UpdateLanguageButtonColors("en");
    }

    public void OnCleanButtonPressed()
    {
        PlayButtonFeedback(cleanReviewModeButton);
        SettingsManager.Instance.ClearReviewModeData();
    }

    public void OnUpdateButtonPressed()
    {
        PlayButtonFeedback(updateButton);
        MainUIManager.Instance.ToggleSettingPanel();
    }

    // 更新音樂按鈕的顏色
        private void UpdateMusicButtonColors(float volume)
    {
        SetTextColor(musicHighButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.85f);
        SetTextColor(musicMediumButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.5f);
        SetTextColor(musicLowButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.25f);
        SetTextColor(musicOffButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0f);
    }

    // 更新音效按鈕的顏色
    private void UpdateSFXButtonColors(float volume)
    {
        SetTextColor(sfxHighButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.85f);
        SetTextColor(sfxMediumButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.5f);
        SetTextColor(sfxLowButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.25f);
        SetTextColor(sfxOffButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0f);
    }

    // 更新語言按鈕的顏色
    private void UpdateLanguageButtonColors(string language)
    {
        SetTextColor(languageChineseButton.GetComponentInChildren<TextMeshProUGUI>(), language == "zh-TW");
        SetTextColor(languageEnglishButton.GetComponentInChildren<TextMeshProUGUI>(), language == "en");
    }

    // 設置按鈕文字顏色
    private void SetTextColor(TextMeshProUGUI text, bool isActive)
    {
        text.color = isActive ? activeTextColor : inactiveTextColor;
    }

    // 設置語言並保存到 PlayerPrefs
    public void SetLanguage(string languageCode)
    {
        // 從 AvailableLocales 中取得對應的 Locale
        Locale selectedLocale = LocalizationSettings.AvailableLocales.Locales
            .Find(locale => locale.Identifier.Code == languageCode);

        if (selectedLocale != null)
        {
            // 設定當前的語言
            LocalizationSettings.SelectedLocale = selectedLocale;

            // 保存語言設置到 PlayerPrefs
            PlayerPrefs.SetString("Language", languageCode);
            PlayerPrefs.Save();

            // 刷新顯示文字
            UpdateAllLocalizedTexts();
        }
        else
        {
            Debug.LogError("Could not find locale for code: " + languageCode);
        }
    }

    // 更新所有 LocalizeStringEvent 來刷新文本
    private void UpdateAllLocalizedTexts()
    {
        foreach (var localizeStringEvent in localizedTextElements)
        {
            localizeStringEvent.RefreshString();  // 重新更新字串
        }
    }

    // 播放按鈕的聲音與視覺反饋
    private void PlayButtonFeedback(Button button)
    {
        // 播放按鈕點擊音效
        AudioManager.Instance.PlaySFX(pressedSFX);

        // 縮小按鈕
        LeanTween.scale(button.gameObject, pressedScale, feedbackDuration).setEaseOutQuad().setOnComplete(() =>
        {
            // 恢復按鈕原來大小
            LeanTween.scale(button.gameObject, Vector3.one, feedbackDuration).setEaseOutQuad();
        });
    }
}