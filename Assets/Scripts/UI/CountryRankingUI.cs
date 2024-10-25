using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class CountryRankingUI : MonoBehaviour
{
    [SerializeField] private GameObject countryItemPrefab;  // 预制件引用，需在 Inspector 中设置
    [SerializeField] private Transform contentParent;       // ScrollView 的 Content 对象，需在 Inspector 中设置

    private string jsonFilePath;
    private Dictionary<string, CountryStats> countryStatsDict = new Dictionary<string, CountryStats>();

    void Start()
    {
        // 初始化文件路径并加载数据
        jsonFilePath = Path.Combine(Application.persistentDataPath, "CountryStats.json");
        LoadCountryStats();
        //Invoke("PopulateCountryRanking", 3f);
        PopulateCountryRanking();
    }

    // 加载 CountryStats.json 文件并解析
    private void LoadCountryStats()
    {
        if (File.Exists(jsonFilePath))
        {
            string json = File.ReadAllText(jsonFilePath);
            CountryStatsList statsList = JsonUtility.FromJson<CountryStatsList>(json);

            foreach (CountryStats stat in statsList.statsList)
            {
                countryStatsDict[stat.countryName] = stat;
            }

            Debug.Log("Loaded country stats from JSON: " + jsonFilePath);
        }
        else
        {
            Debug.LogError("CountryStats.json not found at path: " + jsonFilePath);
        }
    }

    // 动态生成并填充排行榜
    private void PopulateCountryRanking()
    {
        Countries countriesData = CountryFlagsLoader.Instance.GetCountries();

        foreach (CountryStats stat in countryStatsDict.Values)
        {
            // 找到对应的 CountryData 信息
            CountryData countryData = System.Array.Find(countriesData.countries, c => c.cn == stat.countryName);

            if (countryData != null)
            {
                Debug.Log(countryItemPrefab);

                // 创建并设置 CountryItem 预制件
                GameObject item = Instantiate(countryItemPrefab, contentParent);

                // 获取 CountryItemController 脚本
                CountryItemController itemController = item.GetComponent<CountryItemController>();

                // 设置国旗图片路径
                string imgPath = "CountriesFlags/" + countryData.abb2;
                Sprite flagSprite = Resources.Load<Sprite>(imgPath);

                // 设置每个国家的数据
                itemController.SetupItem(flagSprite, countryData.cn, stat.accuracy);
            }
            else
            {
                Debug.LogWarning("Country data not found for: " + stat.countryName);
            }
        }
    }
}