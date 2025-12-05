import {
  PLVCommonConstants,
  PLVLiveChannelType,
  PLVLiveScene,
  PLVLiveSceneSDK,
  PLVPushOrientation,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk';
import {
  derivedStateOf,
  extendArray,
  lateInit,
  MutableObserver,
  mutableStateOf,
  Rect,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { display } from '@kit.ArkUI';
import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus';
import { PLVLWLinkmicItem, PLVLWLinkMicItemAdapter } from './item/PLVLWLinkMicItemAdapter';

@Component
export struct PLVLWLinkMicLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private readonly allLinkmicItems = mutableStateOf<PLVLWLinkmicItem[]>([])
  private readonly userSetMainLinkmicItemId = mutableStateOf<string | undefined>()
  private readonly mainLinkmicItemId = derivedStateOf(() => {
    const pptInMainScreen = this.layoutDataBus.isPPTToMainScreen.value ?? false
    const selectFirstItemType = pptInMainScreen ? 'ppt' : 'viewer'
    return this.userSetMainLinkmicItemId.value
      ?? (this.allLinkmicItems.value ?? []).find(it => it.type === selectFirstItemType)?.id
      ?? (this.allLinkmicItems.value ?? [])[0]?.id
  })
  private readonly mainLinkmicItem = derivedStateOf(() => {
    return this.allLinkmicItems.value?.find(it => it.id === this.mainLinkmicItemId.value)
  })
  private readonly listLinkmicItem = derivedStateOf(() => {
    return extendArray(this.allLinkmicItems.value ?? []).filter(it => it !== this.mainLinkmicItem.value)
  })
  private readonly listLinkmicItemDataSource = new PLVFullUpdateDataSource<PLVLWLinkmicItem>()
  @State private layoutMarginTop: number = 0
  @State private mainItemHeight: number = 0
  // mainItem = [mainLinkmicItem]
  @State private mainItem: PLVLWLinkmicItem[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    // 连麦当前只支持竖屏
    PLVUtils.changeOrientation(false)

    watchStates(() => {
      const channelLinkmicViewers = this.sdk.linkmicManager.channelLinkMicViewers.value ?? []
      const viewerItems = channelLinkmicViewers.map(it => {
        const item = new PLVLWLinkmicItem()
        item.type = 'viewer'
        item.viewer = it
        return item
      })
      let pptItem: PLVLWLinkmicItem | undefined = undefined
      if (this.sdk.channelData.channelType === PLVLiveChannelType.PPT) {
        pptItem = new PLVLWLinkmicItem()
        pptItem.type = 'ppt'
      }
      const allLinkmicItems = extendArray([pptItem, ...viewerItems]).filterNotNull_ext()
      this.allLinkmicItems.setValue(allLinkmicItems)
    }).pushTo(this.observers)
    this.mainLinkmicItem.observe(it => {
      this.mainItem = extendArray([it]).filterNotNull_ext()
    })
      .pushTo(this.observers)
    this.listLinkmicItem.observe(it => this.listLinkmicItemDataSource.update(it))
      .pushTo(this.observers)

    watchStates(() => {
      const screenWidth: number = px2vp(display.getDefaultDisplaySync().width)
      const screenHeight: number = px2vp(display.getDefaultDisplaySync().height)
      const isPortraitTemplate = this.sdk.channelData.liveScene === PLVLiveScene.PORTRAIT_TEMPLATE
      const playerLocation = this.layoutDataBus.playerLocation.value ?? new Rect()
      this.layoutMarginTop = playerLocation.top
      const mainItemMinHeight = screenWidth / 16 * 9
      const mainItemMaxHeight = screenHeight - this.layoutMarginTop - 98
      const mainItem = this.mainLinkmicItem.value
      if (!mainItem || !mainItem.type || mainItem.type === 'ppt' || !isPortraitTemplate) {
        this.mainItemHeight = mainItemMinHeight
      } else {
        const viewerVideoRatio = (mainItem.viewer?.videoWidth.value ?? 1) / (mainItem.viewer?.videoHeight.value ?? 1)
        const isPortrait = viewerVideoRatio < 1
        this.mainItemHeight = isPortrait ? mainItemMaxHeight : mainItemMinHeight
      }
    }).pushTo(this.observers)

    this.updateLocalLinkMicParam()
  }

  build() {
    Column() {
      LinkMicKeepBackgroundTask()

      Column() {
        List({
          space: 8
        }) {
          ListItem().width(0)
          LazyForEach(
            this.listLinkmicItemDataSource,
            (item: PLVLWLinkmicItem) => {
              ListItem() {
                PLVLWLinkMicItemAdapter({
                  pos: 'list',
                  item: item
                }).onClick(() => {
                  this.userSetMainLinkmicItemId.setValue(item.id)
                })
              }
            },
            (item: PLVLWLinkmicItem) => item.id
          )
          ListItem().width(0)
        }
        .listDirection(Axis.Horizontal)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(90)

        Blank().height(8)

        Stack() {
          ForEach(
            this.mainItem,
            (item: PLVLWLinkmicItem) => {
              PLVLWLinkMicItemAdapter({
                pos: 'main',
                item: item
              })
            },
            (item: PLVLWLinkmicItem) => item.id
          )
        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(this.mainItemHeight)
      }
      .width(PLVCommonConstants.FULL_PERCENT)
    }
    .width('100%')
    .margin({
      top: this.layoutMarginTop
    })
  }

  private updateLocalLinkMicParam() {
    const isPortraitScene = this.sdk.channelData.liveScene === PLVLiveScene.PORTRAIT_TEMPLATE
    this.sdk.linkmicManager.setPushOrientation(isPortraitScene ? PLVPushOrientation.PORTRAIT : PLVPushOrientation.LANDSCAPE)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct LinkMicKeepBackgroundTask {
  private readonly context = getContext(this) as common.UIAbilityContext

  async aboutToAppear(): Promise<void> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    const wantAgentObject = await wantAgent.getWantAgent(wantAgentInfo)
    await backgroundTaskManager.startBackgroundRunning(this.context, backgroundTaskManager.BackgroundMode.AUDIO_RECORDING, wantAgentObject)
  }

  build() {
  }

  async aboutToDisappear(): Promise<void> {
    await backgroundTaskManager.stopBackgroundRunning(this.context)
  }
}

class PLVFullUpdateDataSource<T> implements IDataSource {
  private readonly datas: T[] = []
  private readonly listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.datas.length;
  }

  getData(index: number): T {
    return this.datas[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    extendArray(this.listeners).remove_ext(listener);
  }

  update(newDatas: T[]) {
    this.datas.length = 0;
    this.datas.push(...newDatas);
    this.listeners.forEach(it => it.onDataReloaded());
  }
}