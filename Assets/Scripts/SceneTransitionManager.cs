using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public class SceneTransitionManager : MonoBehaviour
{
    public CanvasGroup upperCanvasGroup;  // 上半部的 UI
    public CanvasGroup lowerCanvasGroup;  // 下半部的 UI

    public float fadeDuration = 1f;  // 淡入淡出的時間
    public Vector2 upperStartPos = new Vector2(0, 1000);  // 上半部開始位置 (場景外)
    public Vector2 lowerStartPos = new Vector2(0, -1000); // 下半部開始位置 (場景外)

    private RectTransform upperRect;  // 上半部的 RectTransform
    private RectTransform lowerRect;  // 下半部的 RectTransform

    void Start()
    {
        // 初始化
        upperRect = upperCanvasGroup.GetComponent<RectTransform>();
        lowerRect = lowerCanvasGroup.GetComponent<RectTransform>();

        FadeIn();
    }

    // 場景切換時的 Fade Out 效果
    public void FadeOutAndSwitchScene(string sceneName)
    {
        StartCoroutine(FadeOut(sceneName));
    }

    private IEnumerator FadeOut(string sceneName)
    {
        // 使上半部 UI 往上移動並透明
        LeanTween.move(upperRect, upperStartPos, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        LeanTween.alphaCanvas(upperCanvasGroup, 0, fadeDuration).setEase(LeanTweenType.easeInOutCubic);

        // 使下半部 UI 往下移動並透明
        LeanTween.move(lowerRect, lowerStartPos, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        LeanTween.alphaCanvas(lowerCanvasGroup, 0, fadeDuration).setEase(LeanTweenType.easeInOutCubic);

        yield return new WaitForSeconds(fadeDuration);

        // 完成 Fade Out 後切換場景
        UnityEngine.SceneManagement.SceneManager.LoadScene(sceneName);
    }

    // 場景進入時的 Fade In 效果
    public void FadeIn()
    {
        // 初始化透明度和位置
        upperCanvasGroup.alpha = 0;
        lowerCanvasGroup.alpha = 0;
        upperRect.anchoredPosition = upperStartPos;
        lowerRect.anchoredPosition = lowerStartPos;

        // 使上半部 UI 從上方進入並顯示
        LeanTween.move(upperRect, Vector2.zero, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        LeanTween.alphaCanvas(upperCanvasGroup, 1, fadeDuration).setEase(LeanTweenType.easeInOutCubic);

        // 使下半部 UI 從下方進入並顯示
        LeanTween.move(lowerRect, Vector2.zero, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        LeanTween.alphaCanvas(lowerCanvasGroup, 1, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
    }
}
