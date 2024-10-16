using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class ButtonAutoResize : MonoBehaviour
{
    public Button targetButton; // 目標 Button
    public TextMeshProUGUI buttonText; // Button 裡的文字

    public RectTransform textContainer; // 用來包住文字的容器
    public float padding = 20f; // 文字與邊界的填充

    void Start()
    {
        UpdateButtonSize();
    }

    public void UpdateButtonSize()
    {
        // 根據文字內容取得最佳寬高
        Vector2 preferredSize = new Vector2(
            buttonText.preferredWidth + padding,
            buttonText.preferredHeight + padding
        );

        // 只調整文字容器的尺寸，不影響 Image
        textContainer.sizeDelta = preferredSize;
    }

    // 語言切換時呼叫此方法更新按鈕文字容器尺寸
    public void OnLanguageChanged()
    {
        UpdateButtonSize();
    }
}