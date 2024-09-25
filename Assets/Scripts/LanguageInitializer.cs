using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.Localization.Settings;

public class LanguageInitializer : MonoBehaviour
{
    private void Awake()
    {
        // 加載保存的語言偏好，默認為中文（zh-TW）
        string savedLanguage = PlayerPrefs.GetString("Language", "zh-TW");

        // 從 AvailableLocales 中找到對應的 Locale
        Locale selectedLocale = LocalizationSettings.AvailableLocales.Locales
            .Find(locale => locale.Identifier.Code == savedLanguage);

        // 如果找到對應的語言，設置為當前語言
        if (selectedLocale != null)
        {
            LocalizationSettings.SelectedLocale = selectedLocale;
        }
    }
}