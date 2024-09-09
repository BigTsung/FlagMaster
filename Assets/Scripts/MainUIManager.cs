using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MainUIManager : MonoBehaviour
{
    public string sfx_click_go = "";
    public void OnClickedGo()
    {
        AudioManager.Instance.PlaySFX(sfx_click_go);
        SceneSwitcher.Instance.SwitchToGamePage();
    }
}
