using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MainUIManager : MonoBehaviour
{
    [SerializeField] private string sfx_click_go = "";
    [SerializeField] private string sfx_Toggle_setting_panel = "ui_menu_button_scroll_19";
    public SceneTransitionManager sceneTransitionManager;

    [SerializeField] private GameObject settingPanel;

    public void ToggleSettingPanel()
    {
        Debug.Log("ToggleSettingPanel");
        AudioManager.Instance.PlaySFX(sfx_Toggle_setting_panel);
        

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
        sceneTransitionManager.OnBackButtonClicked();
    }

    public void OnClickedEndless()
    {
        AudioManager.Instance.PlaySFX(sfx_click_go);
        // 設置為Endless模式
        GameManager.currentGameMode = GameManager.GameMode.Endless;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    public void OnClickedSpeedRound()
    {
        AudioManager.Instance.PlaySFX(sfx_click_go);
        // 設置為SpeedRound模式
        GameManager.currentGameMode = GameManager.GameMode.SpeedRound;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    public void OnClickedTwoLives()
    {
        AudioManager.Instance.PlaySFX(sfx_click_go);
        // TwoLives
        GameManager.currentGameMode = GameManager.GameMode.TwoLives;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    public void OnClickedTimedChallenge()
    {
        AudioManager.Instance.PlaySFX(sfx_click_go);
        // 設置為TimedChallenge模式
        GameManager.currentGameMode = GameManager.GameMode.TimedChallenge;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }

    public void OnClickedReview()
    {
        AudioManager.Instance.PlaySFX(sfx_click_go);
        // 設置為TimedChallenge模式
        GameManager.currentGameMode = GameManager.GameMode.Review;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
    }
}
