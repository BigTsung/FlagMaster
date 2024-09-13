using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MainUIManager : MonoBehaviour
{
    public string sfx_click_go = "";
    public SceneTransitionManager sceneTransitionManager;
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
}
