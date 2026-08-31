import {
  PLVCommonConstants, PLVLiveChannelType, PLVLiveScene, PLVLiveSceneSDK, PLVPushOrientation
} from '@polyvharmony/live-scenes-sdk';
import {
  derivedStateOf, extendArray, lateInit, MutableObserver, mutableStateOf, Rect, watchStates
} from '@polyvharmony/media-player-sdk';
import { display } from '@kit.ArkUI';
import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus';
import { PLVLWLinkmicItem, PLVLWLinkMicItemAdapter } from './item/PLVLWLinkMicItemAdapter';
import { PLVLWPlayerControllerLayout } from '../player/controller/PLVLWPlayerControllerLayout';
import { PLVLWDanmuLayout } from '../player/danmu/PLVLWDanmuLayout';

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
  @State private isPortrait: boolean = true
  @State private layoutMarginTop: number = 0
  @State private mainItemHeight: number = 0
  // mainItem = [mainLinkmicItem]
  @State private mainItem: PLVLWLinkmicItem[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
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
      this.isPortrait = this.layoutDataBus.isPortrait.value ?? true
      const screenWidth: number = px2vp(display.getDefaultDisplaySync().width)
      const screenHeight: number = px2vp(display.getDefaultDisplaySync().height)
      const isPortraitTemplate = this.sdk.channelData.liveScene === PLVLiveScene.PORTRAIT_TEMPLATE
      const playerLocation = this.layoutDataBus.playerLocation.value ?? new Rect()
      this.layoutMarginTop = this.isPortrait ? playerLocation.top : 0
      const mainItemMinHeight = screenWidth / 16 * 9
      const mainItemMaxHeight = screenHeight - this.layoutMarginTop - 98
      const mainItem = this.mainLinkmicItem.value
      if (!mainItem || !mainItem.type || mainItem.type === 'ppt' || !isPortraitTemplate) {
        this.mainItemHeight = mainItemMinHeight
      } else {
        const viewerVideoRatio = (mainItem.viewer?.videoWidth.value ?? 1) / (mainItem.viewer?.videoHeight.value ?? 1)
        const isPortrait = viewerVideoRatio === 1 ? isPortraitTemplate : viewerVideoRatio < 1
        this.mainItemHeight = isPortrait ? mainItemMaxHeight : mainItemMinHeight
      }
      // 由于播放器组件在连麦时被移除，这里需要更新播放器区域状态，避免其他依赖播放器区域的组件显示有问题
      const isFullscreen = this.mainItemHeight === mainItemMaxHeight
      this.layoutDataBus.playerFullscreen.setValue(isFullscreen)
      this.updateLocalLinkMicParam()
    }).pushTo(this.observers)
  }

  build() {
    Column() {
      LinkMicKeepBackgroundTask()

      RelativeContainer() {
        if (this.isPortrait) {
          Column() {
            Stack() {
              this.LinkMicItemList(Axis.Horizontal)
            }
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(90)

            Blank().height(8)

            Stack() {
              this.MainLinkMicItem()
            }
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(this.mainItemHeight)
          }
          .id('plvlw_linkmic_content_layout_port')
          .width(PLVCommonConstants.FULL_PERCENT)
        } else {
          Row() {
            Stack() {
              this.MainLinkMicItem()
            }
            .layoutWeight(1)
            .height(PLVCommonConstants.FULL_PERCENT)

            Blank().width(8)

            Stack() {
              this.LinkMicItemList(Axis.Vertical)
            }
            .width(90)
            .height(PLVCommonConstants.FULL_PERCENT)

            Blank().width(8)
          }
          .id('plvlw_linkmic_content_layout_land')
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(PLVCommonConstants.FULL_PERCENT)
        }

        // 弹幕
        PLVLWDanmuLayout()
          .id('plvlw_danmu_layout')
          .hitTestBehavior(HitTestMode.None)
          .width(PLVCommonConstants.FULL_PERCENT)
          .margin({ top: this.isPortrait ? 98 : 0 })
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            bottom: { anchor: this.isPortrait ? 'plvlw_linkmic_content_layout_port' : 'plvlw_linkmic_content_layout_land', align: VerticalAlign.Bottom }
          })

        // 播放器皮肤
        PLVLWPlayerControllerLayout()
          .id('plvlw_player_controller_layout')
          .hitTestBehavior(HitTestMode.Transparent)
          .width(PLVCommonConstants.FULL_PERCENT)
          .margin({ top: this.isPortrait ? 98 : 0 })
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            bottom: { anchor: this.isPortrait ? 'plvlw_linkmic_content_layout_port' : 'plvlw_linkmic_content_layout_land', align: VerticalAlign.Bottom }
          })
      }
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .margin({
      top: this.layoutMarginTop
    })
  }

  @Builder
  private LinkMicItemList(direction: Axis) {
    List({
      space: 8
    }) {
      ListItem().width(0).height(0)
      LazyForEach(
        this.listLinkmicItemDataSource,
        (item: PLVLWLinkmicItem) => {
          ListItem() {
            PLVLWLinkMicItemAdapter({
              pos: 'list',
              item: item
            }).onTouch((event)=>{
                if (event.type === TouchType.Up) {
                  this.userSetMainLinkmicItemId.setValue(item.id)
                }
              })
          }
        },
        (item: PLVLWLinkmicItem) => item.id
      )
      ListItem().width(0).height(0)
    }
    .listDirection(direction)
    .scrollBar(BarState.Off)
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  @Builder
  private MainLinkMicItem() {
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
  }

  private updateLocalLinkMicParam() {
    this.sdk.linkmicManager.setPushOrientation(this.isPortrait ? PLVPushOrientation.PORTRAIT : PLVPushOrientation.LANDSCAPE)
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
