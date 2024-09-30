using UnityEngine;
using UnityEngine.UI;

public class MainUIManager : Singleton<MainUIManager>
{
    //[SerializeField] private string sfx_click_go = "";
    [SerializeField] private string sfx_click_button = "ui_menu_button_scroll_19";
    public SceneTransitionManager sceneTransitionManager;
    [SerializeField] private float feedbackDuration = 0.15f;  // 按鈕縮放動畫持續時間
    [SerializeField] private Vector3 pressedScale = new Vector3(0.9f, 0.9f, 0.9f);  // 按鈕按下時的縮放

    [SerializeField] private GameObject settingPanel;

    [SerializeField] private Button challenageButton;
    [SerializeField] private Button settingButton;
    [SerializeField] private Button backButton;

    [SerializeField] private Button endlessButton;
    [SerializeField] private Button speedRoundButton;
    [SerializeField] private Button twolivesButton;
    [SerializeField] private Button timeChallengeButton;
    [SerializeField] private Button reviewButton;

    public void OnSettingButtonPressed()
    {
        PlayButtonFeedback(settingButton);
        ToggleSettingPanel();
    }


    public void ToggleSettingPanel()
    {
        Debug.Log("ToggleSettingPanel");
        //AudioManager.Instance.PlaySFX(sfx_click_button);

        //PlayButtonFeedback(settingButton);

        if (settingPanel != null)
        {
            //Debug.Log(settingPanel.activeSelf);
            settingPanel.GetComponent<SlidePanel>().TogglePanel();
            //settingPanel.SetActive(!settingPanel.activeSelf);
            //Debug.Log("After: " + settingPanel.activeSelf);
        }
    }

    public void OnBackButtonClicked()
    {
        //AudioManager.Instance.PlaySFX(sfx_click_button);
        PlayButtonFeedback(backButton);
        sceneTransitionManager.OnBackButtonClicked();
    }

    public void OnChallengeButtonClicked()
    {
        //AudioManager.Instance.PlaySFX(sfx_click_button);
        PlayButtonFeedback(challenageButton);
        sceneTransitionManager.OnChallengeButtonClicked();
    }

    public void OnClickedEndless()
    {
        //AudioManager.Instance.PlaySFX(sfx_click_button);
        PlayButtonFeedback(endlessButton);
        // 設置為Endless模式
        GameManager.currentGameMode = GameManager.GameMode.Endless;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    public void OnClickedSpeedRound()
    {
        //AudioManager.Instance.PlaySFX(sfx_click_button);
        PlayButtonFeedback(speedRoundButton);
        // 設置為SpeedRound模式
        GameManager.currentGameMode = GameManager.GameMode.SpeedRound;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    public void OnClickedTwoLives()
    {
        //AudioManager.Instance.PlaySFX(sfx_click_button);
        PlayButtonFeedback(twolivesButton);
        // TwoLives
        GameManager.currentGameMode = GameManager.GameMode.TwoLives;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    public void OnClickedTimedChallenge()
    {
        //AudioManager.Instance.PlaySFX(sfx_click_button);
        PlayButtonFeedback(timeChallengeButton);
        // 設置為TimedChallenge模式
        GameManager.currentGameMode = GameManager.GameMode.TimedChallenge;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    public void OnClickedReview()
    {
        //AudioManager.Instance.PlaySFX(sfx_click_button);
        PlayButtonFeedback(reviewButton);
        // 設置為TimedChallenge模式
        GameManager.currentGameMode = GameManager.GameMode.Review;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    private void PlayButtonFeedback(Button button)
    {
        // 播放按鈕點擊音效
        AudioManager.Instance.PlaySFX(sfx_click_button);

        // 縮小按鈕
        LeanTween.scale(button.gameObject, pressedScale, feedbackDuration).setEaseOutQuad().setOnComplete(() =>
        {
            // 恢復按鈕原來大小
            LeanTween.scale(button.gameObject, Vector3.one, feedbackDuration).setEaseOutQuad();
        });
    }
}
