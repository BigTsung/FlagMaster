using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class SceneTransitionManager : MonoBehaviour
{
    public CanvasGroup upperCanvasGroup;  // 上半部的 UI
    public CanvasGroup lowerCanvasGroup;  // 下半部的 UI，初始只包含挑戰和設定按鈕
    public CanvasGroup fadeCanvasGroup;   // 全屏黑色遮罩的 CanvasGroup，用於黑到透明效果

    public CanvasGroup modeButtonsCanvasGroup;  // 用於控制模式按鈕的 CanvasGroup

    public float fadeDuration = 1f;       // 淡入淡出的時間
    public Vector2 upperStartPos = new Vector2(0, 1000);  // 上半部開始位置 (場景外)
    public Vector2 lowerStartPos = new Vector2(0, -1000); // 下半部開始位置 (場景外)

    private RectTransform upperRect;  // 上半部的 RectTransform
    private RectTransform lowerRect;  // 下半部的 RectTransform
    private RectTransform modeButtonsRect;  // 模式按鈕的 RectTransform

    public Button challengeButton;    // 挑戰按鈕
    public Button settingButton;      // 設置按鈕
    public Button[] modeButtons;      // 各模式按鈕
    public Button backButton;         // 返回按鈕

    void Start()
    {
        // 初始化
        upperRect = upperCanvasGroup.GetComponent<RectTransform>();
        lowerRect = lowerCanvasGroup.GetComponent<RectTransform>();
        modeButtonsRect = modeButtonsCanvasGroup.GetComponent<RectTransform>();

        // 隱藏所有模式按鈕和返回按鈕
        HideModeButtons();

        // 設置挑戰按鈕和返回按鈕的點擊事件
        challengeButton.onClick.AddListener(OnChallengeButtonClicked);
        backButton.onClick.AddListener(OnBackButtonClicked);

        // 執行淡入效果
        FadeIn();
    }

    // 點擊挑戰按鈕時，觸發 UI 淡出和模式按鈕顯示
    private void OnChallengeButtonClicked()
    {
        StartCoroutine(FadeOutAndShowModes());
    }

    // 點擊返回按鈕時，返回到挑戰和設定按鈕顯示狀態
    public void OnBackButtonClicked()
    {
        StartCoroutine(FadeOutModesAndShowChallenge());
    }

    // 隱藏所有模式按鈕
    private void HideModeButtons()
    {
        modeButtonsCanvasGroup.alpha = 0;  // 初始時隱藏模式按鈕
        modeButtonsCanvasGroup.interactable = false;
        modeButtonsCanvasGroup.blocksRaycasts = false;

        backButton.gameObject.SetActive(false);  // 隱藏返回按鈕
    }

    // 顯示所有模式按鈕並淡入效果
    private void ShowModeButtons()
    {
        modeButtonsCanvasGroup.alpha = 1;  // 顯示模式按鈕
        modeButtonsCanvasGroup.interactable = true;
        modeButtonsCanvasGroup.blocksRaycasts = true;

        // 顯示返回按鈕
        backButton.gameObject.SetActive(true);

        // 使用彈出效果逐個顯示按鈕
        foreach (Button btn in modeButtons)
        {
            btn.transform.localScale = Vector3.zero; // 設置初始縮放
            LeanTween.scale(btn.gameObject, Vector3.one, 0.5f).setEaseOutQuint(); // 彈出動畫效果
        }
    }

    // 隱藏模式按鈕並顯示挑戰和設置按鈕
    private IEnumerator FadeOutModesAndShowChallenge()
    {
        // 隱藏模式按鈕
        LeanTween.alphaCanvas(modeButtonsCanvasGroup, 0, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        yield return new WaitForSeconds(0.1f);

        modeButtonsCanvasGroup.interactable = false;
        modeButtonsCanvasGroup.blocksRaycasts = false;

        // 顯示挑戰和設置按鈕
        FadeIn(false);
    }

    // 淡出上下半部分 UI，並淡入模式按鈕
    private IEnumerator FadeOutAndShowModes()
    {
        // 使上半部 UI 往上移動並透明
        LeanTween.move(upperRect, upperStartPos, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        LeanTween.alphaCanvas(upperCanvasGroup, 0, fadeDuration).setEase(LeanTweenType.easeInOutCubic);

        // 使下半部 UI 往下移動並透明
        LeanTween.move(lowerRect, lowerStartPos, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        LeanTween.alphaCanvas(lowerCanvasGroup, 0, fadeDuration).setEase(LeanTweenType.easeInOutCubic);

        yield return new WaitForSeconds(fadeDuration);

        // 淡出完成後顯示模式按鈕並淡入效果
        ShowModeButtons();
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

    // 場景進入時的 Fade In 效果，帶有黑色遮罩逐漸透明
    public void FadeIn(bool maskFirst = true)
    {
        // 初始化透明度和位置
        upperCanvasGroup.alpha = 0;
        lowerCanvasGroup.alpha = 0;
      
        modeButtonsCanvasGroup.alpha = 0; // 初始隱藏模式按鈕

        upperRect.anchoredPosition = upperStartPos;
        lowerRect.anchoredPosition = lowerStartPos;

        if (maskFirst)
        {
            fadeCanvasGroup.alpha = 1;  // 黑色遮罩初始為不透明
            // 使黑色遮罩淡出
            LeanTween.alphaCanvas(fadeCanvasGroup, 0, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        }

        // 使上半部 UI 從上方進入並顯示
        LeanTween.move(upperRect, Vector2.zero, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        LeanTween.alphaCanvas(upperCanvasGroup, 1, fadeDuration).setEase(LeanTweenType.easeInOutCubic);

        // 使下半部 UI 從下方進入並顯示
        LeanTween.move(lowerRect, Vector2.zero, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
        LeanTween.alphaCanvas(lowerCanvasGroup, 1, fadeDuration).setEase(LeanTweenType.easeInOutCubic);
    }
}