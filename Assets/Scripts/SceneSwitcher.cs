using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneSwitcher : Singleton<SceneSwitcher>
{
    public void SwitchToGamePage()
    {
        SceneManager.LoadScene("Page_Game");
    }
}
