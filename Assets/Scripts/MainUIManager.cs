using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MainUIManager : MonoBehaviour
{
    public void OnClickedGo()
    {
        SceneSwitcher.Instance.SwitchToGamePage();
    }
}
