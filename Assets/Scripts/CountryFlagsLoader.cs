using UnityEngine;
using System.Collections.Generic;

[System.Serializable]
public class Countries
{
    public CountryData[] countries;
}

[System.Serializable]
public class CountryData
{
    public string cn;   // Chinese name
    public string en;   // English name
    public string full; // Full name
    public string abb2; // 2-letter abbreviation
    public string abb3; // 3-letter abbreviation
    public string code; // Country code
}

public class CountryFlagsLoader : Singleton<CountryFlagsLoader>
{
    private Countries countries;

    void Awake()
    {
        LoadCountries();
    }

    // 提取 LoadCountries 以增加可讀性
    private void LoadCountries()
    {
        string filePath = "Json/" + "countries_list".Replace(".json", ""); 
        TextAsset jsonFile = Resources.Load<TextAsset>(filePath);

        if (jsonFile != null)
        {
            string jsonContents = jsonFile.text;
            try
            {
                countries = JsonUtility.FromJson<Countries>("{\"countries\":" + jsonContents + "}");
                if (countries == null || countries.countries.Length == 0)
                {
                    Debug.LogError("Failed to parse countries data. The data might be corrupted or invalid.");
                }
            }
            catch (System.Exception e)
            {
                Debug.LogError("Error parsing JSON: " + e.Message);
            }
        }
        else
        {
            Debug.LogError("Cannot find JSON file at path: " + filePath);
        }
    }

    //// 清除 countries.countries 的數據
    //public void ClearAllCountries()
    //{
    //    if (countries != null)
    //    {
    //        countries.countries = new CountryData[0]; // 設置為空數組
    //        Debug.Log("All countries have been cleared.");
    //    }
    //    else
    //    {
    //        Debug.LogWarning("Countries data is null and cannot be cleared.");
    //    }
    //}

    // 提供對國家數據的訪問方法
    public Countries GetCountries()
    {
        if (countries == null || countries.countries.Length == 0)
        {
            Debug.LogWarning("Countries data is not loaded or empty.");
        }
        return countries;
    }
}