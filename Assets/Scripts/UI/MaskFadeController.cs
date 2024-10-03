using UnityEngine;

public class MaskFadeController : MonoBehaviour
{
    [SerializeField] private CanvasGroup fadeCanvasGroup; // 需要淡入淡出的面板
    [SerializeField] private float fadeDuration = 1f; // 淡入淡出的持續時間

    private void Start()
    {
        if (fadeCanvasGroup == null)
        {
            fadeCanvasGroup = GetComponent<CanvasGroup>(); // 若未指定 CanvasGroup，從當前物件獲取
           
        }
        FadeIn();
    }


    // 淡入效果
    public void FadeIn()
    {

        Debug.Log("mask fadeIN");

        fadeCanvasGroup.alpha = 1; // 初始為透明
        fadeCanvasGroup.interactable = false;
        fadeCanvasGroup.blocksRaycasts = false;

        // 使用 LeanTween 進行淡入
        LeanTween.alphaCanvas(fadeCanvasGroup, 0, fadeDuration).setEase(LeanTweenType.easeInOutCubic).setOnComplete(() =>
        {
            fadeCanvasGroup.interactable = true;
            fadeCanvasGroup.blocksRaycasts = true;
        });
    }

    // 淡出效果
    public void FadeOut()
    {
        fadeCanvasGroup.alpha = 0; // 初始為不透明
        fadeCanvasGroup.interactable = true;
        fadeCanvasGroup.blocksRaycasts = true;

        // 使用 LeanTween 進行淡出
        LeanTween.alphaCanvas(fadeCanvasGroup, 1, fadeDuration).setEase(LeanTweenType.easeInOutCubic).setOnComplete(() =>
        {
            fadeCanvasGroup.interactable = false;
            fadeCanvasGroup.blocksRaycasts = false;
        });
    }
}