using UnityEngine;
using UnityEngine.UI;

public class ShiningButtonEffect : MonoBehaviour
{
    public float glowWidth = 0.2f;

    public RectTransform buttonRectTransform;  // 按鈕的 RectTransform
    public Image buttonImage;  // 按鈕的 Image，用來控制顏色變化
    public Color startColor = Color.white;  // 初始顏色
    public Color pulsatingColor = Color.yellow;  // 脈動時的顏色
    public float pulsatingSpeed = 1.0f;  // 控制閃爍速率
    public float scaleAmount = 1.2f;  // 按鈕閃爍時的放大比例

    private Vector3 originalScale;
    private Color originalColor;

    private float previousPulsatingSpeed;
    private float previousScaleAmount;

    void Start()
    {
        originalScale = buttonRectTransform.localScale;
        originalColor = buttonImage.color;

        // 記住當前設置的值
        previousPulsatingSpeed = pulsatingSpeed;
        previousScaleAmount = scaleAmount;

        StartPulsatingEffect();
    }

    void Update()
    {
        // 檢查是否有變化
        if (previousPulsatingSpeed != pulsatingSpeed || previousScaleAmount != scaleAmount)
        {
            // 如果有變化，重新應用效果
            LeanTween.cancel(buttonRectTransform);  // 取消舊的效果
            StartPulsatingEffect();  // 開始新的效果

            // 更新變化後的值
            previousPulsatingSpeed = pulsatingSpeed;
            previousScaleAmount = scaleAmount;

            
        }
    }

    void StartPulsatingEffect()
    {
        // 使用 LeanTween 進行脈動效果（縮放和顏色變化）
        LeanTween.scale(buttonRectTransform, originalScale * scaleAmount, pulsatingSpeed)
                 .setEase(LeanTweenType.easeInOutSine)
                 .setLoopPingPong();

        // 顏色變化效果
        LeanTween.value(gameObject, UpdateColor, startColor, pulsatingColor, pulsatingSpeed)
                 .setEase(LeanTweenType.easeInOutSine)
                 .setLoopPingPong();
    }

    void UpdateColor(Color color)
    {
        buttonImage.color = color;
    }
}