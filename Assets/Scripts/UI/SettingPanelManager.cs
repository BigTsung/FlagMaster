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
        float musicVolume = PlayerPrefs.GetFloat("MusicVolume", 0.4f); // Default volume is 0.5
        float sfxVolume = PlayerPrefs.GetFloat("SFXVolume", 0.75f);     // Default volume is 0.5

        // Update button text colors
        UpdateMusicButtonColors(musicVolume);
        UpdateSFXButtonColors(sfxVolume);

        // Update language button colors
        string currentLanguage = PlayerPrefs.GetString("Language", "zh-TW");
        UpdateLanguageButtonColors(currentLanguage);


        UpdateCleanReviewModeButtonColors();

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
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(musicHighButton, false, () => {
            Debug.Log("button name:" + musicHighButton.name);

            SettingsManager.Instance.SetMusicVolumeHigh();
            UpdateMusicButtonColors(0.75f);
        });

      
    }

    public void OnMusicMediumButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(musicMediumButton, false, () => {
            Debug.Log("button name:" + musicMediumButton.name);

            SettingsManager.Instance.SetMusicVolumeMedium();
            UpdateMusicButtonColors(0.4f);
        });
    }

    public void OnMusicLowButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(musicLowButton, false, () => {
            Debug.Log("button name:" + musicLowButton.name);
            SettingsManager.Instance.SetMusicVolumeLow();
            UpdateMusicButtonColors(0.25f);
        });
    }

    public void OnMusicOffButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(musicOffButton, false, () => {
            Debug.Log("button name:" + musicOffButton.name);
            SettingsManager.Instance.SetMusicVolumeOff();
            UpdateMusicButtonColors(0f);
        });
    }

    // 音效音量按鈕控制
    public void OnSFXHighButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(sfxHighButton, false, () => {
            Debug.Log("button name:" + sfxHighButton.name);
            SettingsManager.Instance.SetSFXVolumeHigh();
            UpdateSFXButtonColors(1f);
        });
    }

    public void OnSFXMediumButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(sfxMediumButton, false, () => {
            Debug.Log("button name:" + sfxMediumButton.name);
            SettingsManager.Instance.SetSFXVolumeMedium();
            UpdateSFXButtonColors(0.75f);
        });
    }

    public void OnSFXLowButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(sfxLowButton, false, () => {
            Debug.Log("button name:" + sfxLowButton.name);
            SettingsManager.Instance.SetSFXVolumeLow();
            UpdateSFXButtonColors(0.5f);
        });
    }

    public void OnSFXOffButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(sfxOffButton, false, () => {
            Debug.Log("button name:" + sfxOffButton.name);
            SettingsManager.Instance.SetSFXVolumeOff();
            UpdateSFXButtonColors(0f);
        });
    }

    // 語言按鈕控制
    public void OnLanguageChineseButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(languageChineseButton, false, () => {
            Debug.Log("button name:" + languageChineseButton.name);
            SetLanguage("zh-TW");
            UpdateLanguageButtonColors("zh-TW");
        });
    }

    public void OnLanguageEnglishButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(languageEnglishButton, false, () => {
            Debug.Log("button name:" + languageEnglishButton.name);
            SetLanguage("en");
            UpdateLanguageButtonColors("en");
        });
    }

    public void OnCleanButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(cleanReviewModeButton, false, () => {
            Debug.Log("button name:" + cleanReviewModeButton.name);
            SettingsManager.Instance.ClearReviewModeData();
        });
    }

    public void OnUpdateButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(updateButton, false, () => {
            Debug.Log("button name:" + updateButton.name);
            MainUIManager.Instance.ToggleSettingPanel();
        });
    }

    // 更新音樂按鈕的顏色
    private void UpdateMusicButtonColors(float volume)
    {
        SetTextColor(musicHighButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.75f);
        SetTextColor(musicMediumButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.4f);
        SetTextColor(musicLowButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.25f);
        SetTextColor(musicOffButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0f);
    }

    // 更新音效按鈕的顏色
    private void UpdateSFXButtonColors(float volume)
    {
        SetTextColor(sfxHighButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 1f);
        SetTextColor(sfxMediumButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.75f);
        SetTextColor(sfxLowButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.5f);
        SetTextColor(sfxOffButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0f);
    }

    // 更新語言按鈕的顏色
    private void UpdateLanguageButtonColors(string language)
    {
        SetTextColor(languageChineseButton.GetComponentInChildren<TextMeshProUGUI>(), language == "zh-TW");
        SetTextColor(languageEnglishButton.GetComponentInChildren<TextMeshProUGUI>(), language == "en");
    }

    private void UpdateCleanReviewModeButtonColors()
    {
        SetTextColor(cleanReviewModeButton.GetComponentInChildren<TextMeshProUGUI>(), false);
        
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
}