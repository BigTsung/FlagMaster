using UnityEngine;
using UnityEngine.UI;
using TMPro;  // Must reference TextMeshPro namespace

public class SettingPanelManager : MonoBehaviour
{
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

    [SerializeField] private Color activeTextColor = Color.white;  // Text color for active button
    [SerializeField] private Color inactiveTextColor = Color.gray; // Text color for inactive buttons

    private void Start()
    {
        // default: hide SettingPanel
        this.gameObject.SetActive(false);

        // Initialize button color states
        InitializeUI();
    }

    private void InitializeUI()
    {
        // Load the saved settings and set button colors accordingly
        float musicVolume = PlayerPrefs.GetFloat("MusicVolume", 0.5f); // Default volume is 0.5
        float sfxVolume = PlayerPrefs.GetFloat("SFXVolume", 0.5f);     // Default volume is 0.5

        // Update button text colors
        UpdateMusicButtonColors(musicVolume);
        UpdateSFXButtonColors(sfxVolume);

        // Update language button colors
        string currentLanguage = PlayerPrefs.GetString("Language", "Chinese");
        UpdateLanguageButtonColors(currentLanguage);
    }

    // Music volume button controls
    public void OnMusicHighButtonPressed()
    {
        SettingsManager.Instance.SetMusicVolumeHigh();
        UpdateMusicButtonColors(0.85f);
    }

    public void OnMusicMediumButtonPressed()
    {
        SettingsManager.Instance.SetMusicVolumeMedium();
        UpdateMusicButtonColors(0.5f);
    }

    public void OnMusicLowButtonPressed()
    {
        SettingsManager.Instance.SetMusicVolumeLow();
        UpdateMusicButtonColors(0.25f);
    }

    public void OnMusicOffButtonPressed()
    {
        SettingsManager.Instance.SetMusicVolumeOff();
        UpdateMusicButtonColors(0f);
    }

    // SFX volume button controls
    public void OnSFXHighButtonPressed()
    {
        SettingsManager.Instance.SetSFXVolumeHigh();
        UpdateSFXButtonColors(0.85f);
    }

    public void OnSFXMediumButtonPressed()
    {
        SettingsManager.Instance.SetSFXVolumeMedium();
        UpdateSFXButtonColors(0.5f);
    }

    public void OnSFXLowButtonPressed()
    {
        SettingsManager.Instance.SetSFXVolumeLow();
        UpdateSFXButtonColors(0.25f);
    }

    public void OnSFXOffButtonPressed()
    {
        SettingsManager.Instance.SetSFXVolumeOff();
        UpdateSFXButtonColors(0f);
    }

    // Language button controls
    public void OnLanguageChineseButtonPressed()
    {
        PlayerPrefs.SetString("Language", "Chinese");
        PlayerPrefs.Save();
        UpdateLanguageButtonColors("Chinese");
    }

    public void OnLanguageEnglishButtonPressed()
    {
        PlayerPrefs.SetString("Language", "English");
        PlayerPrefs.Save();
        UpdateLanguageButtonColors("English");
    }

    // Update the music button colors based on the volume
    private void UpdateMusicButtonColors(float volume)
    {
        SetTextColor(musicHighButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.85f);
        SetTextColor(musicMediumButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.5f);
        SetTextColor(musicLowButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.25f);
        SetTextColor(musicOffButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0f);
    }

    // Update the SFX button colors based on the volume
    private void UpdateSFXButtonColors(float volume)
    {
        SetTextColor(sfxHighButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.85f);
        SetTextColor(sfxMediumButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.5f);
        SetTextColor(sfxLowButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0.25f);
        SetTextColor(sfxOffButton.GetComponentInChildren<TextMeshProUGUI>(), volume == 0f);
    }

    // Update the language button colors based on the current selection
    private void UpdateLanguageButtonColors(string language)
    {
        SetTextColor(languageChineseButton.GetComponentInChildren<TextMeshProUGUI>(), language == "Chinese");
        SetTextColor(languageEnglishButton.GetComponentInChildren<TextMeshProUGUI>(), language == "English");
    }

    // Set the text color of a button
    private void SetTextColor(TextMeshProUGUI text, bool isActive)
    {
        text.color = isActive ? activeTextColor : inactiveTextColor;
    }
}