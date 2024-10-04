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
        UIEffect defaultEffect = new UIEffect(sfx: sfx_click_button);
        defaultEffect.PlayButtonFeedback(settingButton, false, () => {
            Debug.Log("button name:" + settingButton.name);
            ToggleSettingPanel();
        });
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
        UIEffect defaultEffect = new UIEffect(sfx: sfx_click_button);
        defaultEffect.PlayButtonFeedback(backButton, false, () => {
            Debug.Log("button name:" + backButton.name);
            sceneTransitionManager.OnBackButtonClicked();
        });
    }

    public void OnChallengeButtonClicked()
    {
        UIEffect defaultEffect = new UIEffect(sfx: sfx_click_button);
        defaultEffect.PlayButtonFeedback(challenageButton, false, () => {
            Debug.Log("button name:" + challenageButton.name);
            sceneTransitionManager.OnChallengeButtonClicked();
        });
    }

    public void OnClickedEndless()
    {
        UIEffect defaultEffect = new UIEffect(sfx: sfx_click_button);
        defaultEffect.PlayButtonFeedback(endlessButton, false, () => {
            Debug.Log("button name:" + endlessButton.name);
            GameManager.currentGameMode = GameManager.GameMode.Endless;
            sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
        });
    }

    public void OnClickedSpeedRound()
    {
        UIEffect defaultEffect = new UIEffect(sfx: sfx_click_button);
        defaultEffect.PlayButtonFeedback(speedRoundButton, false, () => {
            Debug.Log("button name:" + speedRoundButton.name);
            GameManager.currentGameMode = GameManager.GameMode.SpeedRound;
            sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
        });
    }

    public void OnClickedTwoLives()
    {
        UIEffect defaultEffect = new UIEffect(sfx: sfx_click_button);
        defaultEffect.PlayButtonFeedback(twolivesButton, false, () => {
            Debug.Log("button name:" + twolivesButton.name);
            GameManager.currentGameMode = GameManager.GameMode.TwoLives;
            sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
        });
    }

    public void OnClickedTimedChallenge()
    {
        UIEffect defaultEffect = new UIEffect(sfx: sfx_click_button);
        defaultEffect.PlayButtonFeedback(timeChallengeButton, false, () => {
            Debug.Log("button name:" + timeChallengeButton.name);
            GameManager.currentGameMode = GameManager.GameMode.TimedChallenge;
            sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
        });
    }

    public void OnClickedReview()
    {
        UIEffect defaultEffect = new UIEffect(sfx: sfx_click_button);
        defaultEffect.PlayButtonFeedback(reviewButton, false, () => {
            Debug.Log("button name:" + reviewButton.name);
            GameManager.currentGameMode = GameManager.GameMode.Review;
            sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
        });
    }
}
