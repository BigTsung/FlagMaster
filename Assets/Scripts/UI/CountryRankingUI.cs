using System.Collections.Generic;
using UnityEngine.Localization.Settings;
using UnityEngine;
using System.IO;
using System.Linq;

public class CountryRankingUI : Singleton<CountryRankingUI>
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

    public void ClearAllCountryStatsDict()
    {
        countryStatsDict.Clear();
    }

    // 动态生成并填充排行榜
    public void PopulateCountryRanking()
    {
        // 清空 contentParent 的所有子对象
        foreach (Transform child in contentParent)
        {
            Debug.Log("Destroy all elements");
            Destroy(child.gameObject);
        }

        Countries countriesData = CountryFlagsLoader.Instance.GetCountries();

        // 根据 accuracy 从低到高排序
        var sortedStats = countryStatsDict.Values.OrderBy(stat => stat.accuracy).ToList();

        foreach (CountryStats stat in sortedStats)
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

                Debug.Log(" LocalizationSettings.SelectedLocale.Identifier.Code: " + LocalizationSettings.SelectedLocale.Identifier.Code);

                string countryDadaText = LocalizationSettings.SelectedLocale.Identifier.Code == "en"
                ? countryData.en
                : countryData.cn;

                // 设置每个国家的数据，并去掉小数点
                float accuracy = Mathf.RoundToInt(stat.accuracy);
                itemController.SetupItem(flagSprite, countryDadaText, accuracy);
            }
            else
            {
                Debug.LogWarning("Country data not found for: " + stat.countryName);
            }
        }
    }
}