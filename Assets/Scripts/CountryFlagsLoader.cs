using UnityEngine;
using System.IO;
using System.Collections.Generic;

//[System.Serializable]
//public class Countries
//{
//    public List<>
//}

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


    //public string jsonFileName = "Json/countries_list";
    void Awake()
    {
        string filePath = "Json/" + "countries_list".Replace(".json", "");
        //Debug.Log(filePath);
        TextAsset jsonFile = Resources.Load<TextAsset>(filePath);

        if (jsonFile != null)
        {
            string jsonContents = jsonFile.text;

            //Debug.Log("jsonContents: " + jsonContents);


            countries = JsonUtility.FromJson<Countries>("{\"countries\":" + jsonContents + "}"); ;

            //Debug.Log("data: " + countries);

            //foreach (CountryData country in countries.countries)
            //{
            //    Debug.Log("Chinese Name: " + country.cn);
            //    //Debug.Log("English Name: " + country.en);
            //    //Debug.Log("Full Name: " + country.full);
            //    //Debug.Log("2-Letter Abbreviation: " + country.abb2);
            //    //Debug.Log("3-Letter Abbreviation: " + country.abb3);
            //    //Debug.Log("Country Code: " + country.code);
            //}

        }
        else
        {
            Debug.LogError("Cannot file json file：" + filePath);
        }
    }

    public Countries GetCountries()
    {
        return countries;
    }
}
