using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;

public class FlagBackgroundManager : MonoBehaviour
{
    public GameObject flagPrefab;  // 使用 GameObject 來顯示國旗
    public Transform parentTransform;  // 父物件用來放置旗幟
    public int maxFlags = 5;  // 最大同時顯示的旗幟數量
    public float animationDuration = 3f;  // 動畫持續時間
    public float flagSpawnInterval = 1f;  // 旗幟生成的間隔時間

    private List<CountryData> countryList;
    private List<GameObject> activeFlags = new List<GameObject>();
    private RectTransform canvasRectTransform; // 取得 Canvas 的範圍用於計算飛入飛出位置

    void Start()
    {
        countryList = new List<CountryData>(CountryFlagsLoader.Instance.GetCountries().countries);
        canvasRectTransform = parentTransform.GetComponent<RectTransform>(); // 取得 Canvas 大小
        StartCoroutine(DisplayRandomFlags());
    }

    IEnumerator DisplayRandomFlags()
    {
        while (true)
        {
            if (activeFlags.Count < maxFlags)
            {
                // 創建旗幟 GameObject
                GameObject flag = Instantiate(flagPrefab, parentTransform);
                activeFlags.Add(flag);

                // 隨機選擇一個國家
                int randomIndex = Random.Range(0, countryList.Count);
                CountryData selectedCountry = countryList[randomIndex];

                // 加載國旗圖案
                string flagPath = "CountriesFlags/" + selectedCountry.abb2;
                Sprite flagSprite = Resources.Load<Sprite>(flagPath);

                // 設置旗幟圖案到 GameObject 的第一個子物件的 Image
                Image childImage = flag.transform.GetChild(0).GetComponent<Image>();
                if (flagSprite != null && childImage != null)
                {
                    childImage.sprite = flagSprite;
                }

                // 計算旗幟的 RectTransform，確保是 UI 物件的錨點範圍
                RectTransform flagRect = flag.GetComponent<RectTransform>();

                // 獲取國旗的實際大小
                Vector2 flagSize = new Vector2(flagRect.rect.width * flagRect.localScale.x, flagRect.rect.height * flagRect.localScale.y);

                // 確保國旗能完全穿越畫面，並且計算飛入和飛出的準確位置
                Vector2 startPosition = GetRandomOffScreenPosition(flagSize, out int startEdge);   // 起始位置
                Vector2 exitPosition = GetDifferentOffScreenPosition(flagSize, startEdge);    // 終點位置

                // 設置旗幟的位置為飛入位置
                flagRect.anchoredPosition = startPosition;

                // 動畫效果 - 旗幟從屏幕外飛入並飛出
                LeanTween.move(flagRect, exitPosition, animationDuration).setEaseLinear();

                // 設置旗幟飛出後銷毀
                StartCoroutine(RemoveFlagAfterTime(flag, animationDuration));

                // 等待間隔時間
                yield return new WaitForSeconds(flagSpawnInterval);
            }
        }
    }

    // 隨機從畫面外生成旗幟的位置，並確保國旗完全飛入畫面
    Vector2 GetRandomOffScreenPosition(Vector2 flagSize, out int edge)
    {
        float flagWidth = flagSize.x;
        float flagHeight = flagSize.y;

        // 根據畫面的寬度和高度計算畫面外的位置
        float x = 0, y = 0;
        edge = Random.Range(0, 4);  // 隨機選擇一個邊 (0=左, 1=右, 2=上, 3=下)

        // 確保旗幟不僅僅進入邊緣，而是完全穿越畫面中央部分
        float minY = -canvasRectTransform.rect.height / 4; // 確保不在邊緣移動
        float maxY = canvasRectTransform.rect.height / 4;

        switch (edge)
        {
            case 0: // 左邊，從畫面外左邊飛入
                x = -canvasRectTransform.rect.width / 2 - flagWidth;
                y = Random.Range(minY, maxY); // 確保 Y 軸在畫面中央區域
                break;
            case 1: // 右邊，從畫面外右邊飛入
                x = canvasRectTransform.rect.width / 2 + flagWidth;
                y = Random.Range(minY, maxY);
                break;
            case 2: // 上邊，從畫面外上邊飛入
                x = Random.Range(-canvasRectTransform.rect.width / 2 + flagWidth / 2, canvasRectTransform.rect.width / 2 - flagWidth / 2);
                y = canvasRectTransform.rect.height / 2 + flagHeight;
                break;
            case 3: // 下邊，從畫面外下邊飛入
                x = Random.Range(-canvasRectTransform.rect.width / 2 + flagWidth / 2, canvasRectTransform.rect.width / 2 - flagWidth / 2);
                y = -canvasRectTransform.rect.height / 2 - flagHeight;
                break;
        }

        return new Vector2(x, y);
    }

    // 確保旗幟從不同的邊飛出，並確保國旗完全飛出畫面
    Vector2 GetDifferentOffScreenPosition(Vector2 flagSize, int startEdge)
    {
        float flagWidth = flagSize.x;
        float flagHeight = flagSize.y;

        int exitEdge;
        do
        {
            exitEdge = Random.Range(0, 4); // 確保選擇的邊不同於起始邊
        } while (exitEdge == startEdge);

        float x = 0, y = 0;

        float minY = -canvasRectTransform.rect.height / 4;
        float maxY = canvasRectTransform.rect.height / 4;

        switch (exitEdge)
        {
            case 0: // 左邊，飛出畫面外左邊
                x = -canvasRectTransform.rect.width / 2 - flagWidth;
                y = Random.Range(minY, maxY);
                break;
            case 1: // 右邊，飛出畫面外右邊
                x = canvasRectTransform.rect.width / 2 + flagWidth;
                y = Random.Range(minY, maxY);
                break;
            case 2: // 上邊，飛出畫面外上邊
                x = Random.Range(-canvasRectTransform.rect.width / 2 + flagWidth / 2, canvasRectTransform.rect.width / 2 - flagWidth / 2);
                y = canvasRectTransform.rect.height / 2 + flagHeight;
                break;
            case 3: // 下邊，飛出畫面外下邊
                x = Random.Range(-canvasRectTransform.rect.width / 2 + flagWidth / 2, canvasRectTransform.rect.width / 2 - flagWidth / 2);
                y = -canvasRectTransform.rect.height / 2 - flagHeight;
                break;
        }

        return new Vector2(x, y);
    }

    // 移除旗幟動畫後將旗幟銷毀
    IEnumerator RemoveFlagAfterTime(GameObject flag, float delay)
    {
        yield return new WaitForSeconds(delay);

        activeFlags.Remove(flag);
        Destroy(flag);
    }
}