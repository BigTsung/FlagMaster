using UnityEngine;

public class SlidePanel : MonoBehaviour
{
    public float animationDuration = 0.5f;  // 動畫持續時間
    public LeanTweenType easeTypeIn = LeanTweenType.easeOutQuad;  // 從屏幕外進入的動畫
    public LeanTweenType easeTypeOut = LeanTweenType.easeInQuad;  // 從屏幕滑出的動畫
    public bool isVisible = false;  // Panel 是否可見

    private RectTransform rectTransform;

    private void Awake()
    {
        rectTransform = GetComponent<RectTransform>();
        Debug.Log("rectTransform: " + rectTransform);
    }

    private void Start()
    {
        // 可以選擇在 Start 的時候讓 Panel 預設不可見
        if (!isVisible)
        {
            rectTransform.anchoredPosition = new Vector2(0, -Screen.height);  // 初始位置在屏幕外
            //gameObject.SetActive(false);
        }
    }

    // 顯示 Panel 並滑動到屏幕中
    public void ShowPanel()
    {
        // 檢查並初始化 rectTransform
        if (rectTransform == null)
        {
            rectTransform = GetComponent<RectTransform>();
        }

        // 先將 Panel 的 RectTransform 位置移到屏幕外
        rectTransform.anchoredPosition = new Vector2(0, -Screen.height);

        // 確保 Panel 被啟用
        gameObject.SetActive(true);
        isVisible = true;

        // 從屏幕底部滑動進來
        LeanTween.moveY(rectTransform, 0, animationDuration).setEase(easeTypeIn);
    }

    // 隱藏 Panel 並從屏幕滑出
    public void HidePanel()
    {
        // 從屏幕滑出並在動畫結束後隱藏 Panel
        LeanTween.moveY(rectTransform, -Screen.height, animationDuration).setEase(easeTypeOut).setOnComplete(() =>
        {
            gameObject.SetActive(false);
            isVisible = false;
        });
    }

    // 切換 Panel 的可見狀態
    public void TogglePanel()
    {
        Debug.Log("TogglePanel");
        if (isVisible)
        {
            HidePanel();
        }
        else
        {
            ShowPanel();
        }
    }
}