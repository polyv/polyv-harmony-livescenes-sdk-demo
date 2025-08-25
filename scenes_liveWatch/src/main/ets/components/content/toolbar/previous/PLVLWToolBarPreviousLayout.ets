import { PLVChannelData, PLVCommonConstants, PLVDeviceUtils, PLVLiveScene, PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { createDialog, showDialog } from '../../../../common/PLVLWGlobalStateDialog'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'
import { PLVLWChapterTabLayout } from '../../tabcontent/tab/PLVLWChapterTabLayout'
import { PLVLWPreviousTabLayout, PreviousTabData } from '../../tabcontent/tab/PLVLWPreviousTabLayout'

@Component
export struct PLVLWToolBarPreviousIcon {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @LocalStorageLink('channelData') channelData?: PLVChannelData = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State viewWidth: number = 36
  @State viewHeight: number = 36

  aboutToAppear(): void {
    createPreviousDialog(this.sdk.uniqueId, new PreviousTabData(this.sdk, this.channelData, this.layoutDataBus))
  }

  build() {
    if (PLVLoginType.PLAYBACK === this.channelData?.loginType
      && PLVLiveScene.PORTRAIT_TEMPLATE === this.channelData?.liveScene
      && (this.channelData.hasPreviousMenu() || this.channelData.hasChapterMenu())) {
      Image($r('app.media.plvlw_tool_bar_playback_list_icon'))
        .width(this.viewWidth)
        .height(this.viewHeight)
        .onClick(() => {
          showPreviousDialog(this.sdk.uniqueId)
        })
    }
  }
}

function createPreviousDialog(sdkId: number, data: PreviousTabData) {
  createDialog({
    uniqueId: sdkId,
    name: 'previous',
    wrapBuilder: wrapBuilder(previousDialogLayout),
    params: data
  })
}

function showPreviousDialog(sdkId: number, isShow: boolean = true) {
  showDialog({
    uniqueId: sdkId,
    name: 'previous',
    isShow: isShow
  })
}

@Builder
function previousDialogLayout(previousTabData: PreviousTabData) {
  PLVLWPreviousDialogLayout({ previousTabData: previousTabData })
}

@Component
export struct PLVLWPreviousDialogLayout {
  @State @Require previousTabData?: PreviousTabData = undefined
  @State channelData: PLVChannelData | undefined = undefined
  @State private isPortrait: boolean = true
  @State private hasPreviousTab: boolean = false
  @State private hasChapterTab: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.channelData = this.previousTabData?.channelData
    this.hasPreviousTab = this.channelData?.hasPreviousMenu() ?? false
    this.hasChapterTab = this.channelData?.hasChapterMenu() ?? false
    watchStates(() => {
      this.isPortrait = this.previousTabData?.layoutDataBus?.isPortrait.value ?? true
    }).pushTo(this.observers)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    Stack() {
      Tabs() {
        if (this.hasPreviousTab) {
          TabContent() {
            PLVLWPreviousTabLayout({ previousTabData: this.previousTabData, isDialogStyle: true })
          }
          .tabBar(this.tabBarStyle(this.channelData?.getPreviousMenuName($r('app.string.plv_sdk_live_menu_name_previous'))))
        }
        if (this.hasChapterTab) {
          TabContent() {
            PLVLWChapterTabLayout({ chapterTabData: this.previousTabData, isDialogStyle: true })
          }
          .tabBar(this.tabBarStyle($r('app.string.plv_sdk_live_menu_name_micro_chapter')))
        }
      }
      .barMode(BarMode.Scrollable)
      .barHeight(42)
      .padding({
        top: 4,
        bottom: PLVDeviceUtils.getNavigationIndicatorHeight() + 6
      })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
    .borderRadius({
      topLeft: 12,
      topRight: this.isPortrait ? 12 : 0,
      bottomLeft: this.isPortrait ? 0 : 12,
      bottomRight: 0
    })
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : PLVDeviceUtils.getMinDisplaySide())
    .height(this.isPortrait ? '60%' : PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_neutral_dark_white'))
  }

  tabBarStyle(tabName?: ResourceStr) {
    return new SubTabBarStyle(tabName ?? '')
      .padding({
        left: 12,
        right: 12,
        top: 0,
        bottom: 4
      })
      .indicator({
        color: $r('app.color.plvlw_theme_bg_blue'),
        height: 2,
        borderRadius: 2
      })
      .labelStyle({ unselectedColor: $r('app.color.plvlw_neutral_light_black_60'), selectedColor: $r('app.color.plvlw_neutral_light_black_80') })
  }
}