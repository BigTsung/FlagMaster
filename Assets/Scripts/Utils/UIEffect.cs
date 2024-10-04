using UnityEngine;
using UnityEngine.UI;

public class UIEffect
{
    private string pressedSFX;
    private float feedbackDuration;
    private Vector3 pressedScale;

    // 構造函數，允許傳入自定義的參數，如果沒有提供則使用默認值
    public UIEffect(string sfx = "ui_menu_button_scroll_19", float duration = 0.15f, Vector3 scale = default(Vector3))
    {
        pressedSFX = sfx;
        feedbackDuration = duration;
        pressedScale = scale == default(Vector3) ? new Vector3(0.9f, 0.9f, 0.9f) : scale;
    }

    public void PlayButtonFeedback(Button button, bool waitForFeedback, System.Action onComplete = null)
    {
        // 播放按鈕點擊音效
        AudioManager.Instance.PlaySFX(pressedSFX);

        // 縮小按鈕
        LeanTween.scale(button.gameObject, pressedScale, feedbackDuration).setEaseOutQuad().setOnComplete(() =>
        {
            // 恢復按鈕原來大小
            LeanTween.scale(button.gameObject, Vector3.one, feedbackDuration).setEaseOutQuad().setOnComplete(() =>
            {
                // 如果需要等待反饋效果完成
                if (waitForFeedback && onComplete != null)
                {
                    onComplete?.Invoke();  // 執行傳入的後續操作
                }
            });
        });

        // 如果不需要等待反饋效果完成，立即執行後續操作
        if (!waitForFeedback && onComplete != null)
        {
            onComplete?.Invoke();
        }
    }
}