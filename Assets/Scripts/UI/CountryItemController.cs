using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class CountryItemController : MonoBehaviour
{
    public Image flagImage; // 用于显示国旗的Image组件
    public TextMeshProUGUI nameText; // 用于显示国家名称的TextMeshPro组件
    public TextMeshProUGUI accuracyText; // 用于显示答对率的TextMeshPro组件

    // 设置 CountryItem 的内容
    public void SetupItem(Sprite flagSprite, string countryName, float accuracy)
    {
        flagImage.sprite = flagSprite; // 设置国旗图片
        nameText.text = countryName; // 设置国家名称
        //accuracyText.text = accuracy;
        accuracyText.text = Mathf.FloorToInt(accuracy).ToString() + "%";
    }
}