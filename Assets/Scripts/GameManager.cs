using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class GameManager : MonoBehaviour
{
    private List<CountryData> dataList = new List<CountryData>();

    [SerializeField] private Image imageFlag;
    [SerializeField] private TextMeshProUGUI text1;
    [SerializeField] private TextMeshProUGUI text2;
    [SerializeField] private TextMeshProUGUI text3;
    [SerializeField] private TextMeshProUGUI text4;

    // Start is called before the first frame update
    void Start()
    {
        Countries countries = CountryFlagsLoader.Instance.GetCountries();

        dataList = new List<CountryData>(countries.countries);
        Debug.Log(countries.countries.Length);
        Debug.Log(dataList.Count);

        //foreach(CountryData data in dataList)
        //{
        //    Debug.Log(data.cn);
        //}
        
    }

    public void GetRandomFourCountries()
    {
        System.Random rng = new System.Random();

        dataList = dataList.OrderBy(x => rng.Next()).ToList();

        
        List<CountryData> selectedCountries = dataList.Take(4).ToList();
        System.Random rngin4 = new System.Random();
        int target = rngin4.Next(4);


        string imgPath = "CountriesFlags/" + selectedCountries[target].abb2;
        Debug.Log("imgPath: "+ imgPath);
        Sprite flagIcon = Resources.Load<Sprite>(imgPath);
        imageFlag.sprite = flagIcon;

        for (int i = 0; i < selectedCountries.Count; i++)
        {
            CountryData country = selectedCountries[i];
            if (i == 0)
            {
                text1.text = country.cn;
            }
            else if (i == 1)
            {
                text2.text = country.cn;
            }
            else if(i == 2)
            {
                text3.text = country.cn;
            }
            else if(i == 3)
            {
                text4.text = country.cn;
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
