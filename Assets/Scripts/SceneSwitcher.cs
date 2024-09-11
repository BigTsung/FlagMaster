using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneSwitcher : Singleton<SceneSwitcher>
{
    public SceneTransitionManager sceneTransitionManager;

    public void SwitchToGamePage()
    {
        sceneTransitionManager.FadeOutAndSwitchScene("Page_Game");
        // SceneManager.LoadScene("Page_Game");
    }
}
