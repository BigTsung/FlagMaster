using UnityEngine;
using TMPro; // 引入 TextMeshPro

public class VersionDisplay : MonoBehaviour
{
    public TextMeshProUGUI versionText; // TextMeshProUGUI 用於顯示文字

    void Start()
    {
        //string build = Application.unityVersion; // Unity 版本號
        //versionText.text = $"Version {version}\nBuild {buildNumber}";
        versionText.text = $"v{Application.version} b{BuildSetting.Instance.buildNumber}";
    }
}