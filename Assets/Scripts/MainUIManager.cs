using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MainUIManager : MonoBehaviour
{
    public string sfx_click_go = "";
    public SceneTransitionManager sceneTransitionManager;
    public void OnClickedGo()
    {
        AudioManager.Instance.PlaySFX(sfx_click_go);
          // 設置為普通模式
        GameManager.currentGameMode = GameManager.GameMode.Endless;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
        // SceneSwitcher.Instance.SwitchToGamePage();
    }

    public void OnClickedTimedChallenge()
    {
        AudioManager.Instance.PlaySFX(sfx_click_go);
          // 設置為普通模式
        GameManager.currentGameMode = GameManager.GameMode.TimedChallenge;
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
        // SceneSwitcher.Instance.SwitchToGamePage();
    }
}
