import { PLVChannelData, PLVCommonConstants, PLVLiveSceneSDK, PLVLogger, PLVPPTStatus } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, PLVLiveStatusEnum, PLVMediaPlayerState, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

const TAG = '[PLVLWPlayerControllerPPTStatusLayout]'

@Component
export struct PLVLWPlayerControllerPPTStatusLayout {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @State viewHeight: number = 38
  @State isLayoutVisible: boolean = false
  @State previousEnable: boolean = false
  @State nextEnable: boolean = false
  // 当前页
  @State currentPage: number = 0;
  // 最大页
  @State maxPage: number = 0;
  // 讲师操作的最大页面
  @State teacherMaxPage: number = 0;
  @State pageProgressText: string = '1/1'
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onLayoutData()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    if (this.channelData?.liveDetail?.isViewerPptTurningEnabled()) {
      Row() {
        Image($r('app.media.plvlw_controller_ppt_previous_normal'))
          .width(30)
          .padding({ left: 4, right: 4 })
          .objectFit(ImageFit.Contain)
          .height(PLVCommonConstants.FULL_PERCENT)
          .opacity(this.previousEnable ? 1 : 0.5)
          .onClick(() => {
            PLVLogger.info(TAG, 'gotoPreviousStep, previousEnable=' + this.previousEnable)
            if (!this.previousEnable) {
              return
            }
            this.gotoPreviousStep()
          })

        Text(this.pageProgressText)
          .fontColor($r('app.color.plvlw_neutral_dark_white'))
          .fontSize(12)
          .padding({ left: 6, right: 6 })
          .margin({ left: 6, right: 6 })
          .onClick(() => {
            this.goBackTeacherPage()
          })

        Image($r('app.media.plvlw_controller_ppt_next_normal'))
          .width(30)
          .padding({ left: 4, right: 4 })
          .objectFit(ImageFit.Contain)
          .height(PLVCommonConstants.FULL_PERCENT)
          .opacity(this.nextEnable ? 1 : 0.5)
          .onClick(() => {
            PLVLogger.info(TAG, 'gotoNextStep, nextEnable=' + this.nextEnable)
            if (!this.nextEnable) {
              return
            }
            this.gotoNextStep()
          })
      }
      .onClick(() => {
      })
      .alignItems(VerticalAlign.Center)
      .width(PLVCommonConstants.AUTO)
      .borderRadius(this.viewHeight / 2)
      .padding({ left: 6, right: 6 })
      .backgroundColor($r('app.color.plvlw_neutral_light_black_60'))
      .height(this.viewHeight)
      .visibility(this.isLayoutVisible ? Visibility.Visible : Visibility.Hidden)
    }
  }

  onLayoutData() {
    watchStates(() => {
      const isPPTToMainScreen = this.layoutDataBus.isPPTToMainScreen.value ?? false
      const liveStatus = this.sdk?.playerManager.mainMediaPlayer.getBusinessListenerRegistry().liveStatus.value
      const playerStatus = this.sdk?.playerManager.mainMediaPlayer.getStateListenerRegistry().playerState.value
      const playerStatusVisible = playerStatus !== PLVMediaPlayerState.STATE_IDLE && playerStatus !== PLVMediaPlayerState.STATE_ERROR
      const playerStatusNone = !playerStatusVisible
      const liveStatusNone = liveStatus === PLVLiveStatusEnum.PAUSE || liveStatus === PLVLiveStatusEnum.NO_LIVE
      if (liveStatusNone || playerStatusNone) {
        this.isLayoutVisible = false
      } else {
        this.isLayoutVisible = isPPTToMainScreen
      }

      const pptStatus = this.layoutDataBus.pptStatus.value ?? undefined
      this.handlePageData(pptStatus)
    }).pushTo(this.observers)
  }

  handlePageData(pptStatus?: PLVPPTStatus) {
    if (pptStatus?.maxTeacherOp !== undefined) {
      this.teacherMaxPage = pptStatus.maxTeacherOp.pageId ?? 0
      if (pptStatus.autoId !== -1) {
        this.maxPage = pptStatus.total ?? 0
        this.currentPage = pptStatus.pageId ?? 0
      }
      this.updateStep()
    }
  }

  updateStep() {
    const page = this.currentPage + 1
    if (page <= 1) {
      this.previousEnable = false
      this.currentPage = 0
    } else {
      this.previousEnable = true
    }
    if (this.currentPage >= this.teacherMaxPage) {
      this.nextEnable = false
      this.currentPage = this.teacherMaxPage
    } else {
      this.nextEnable = true
    }
    this.pageProgressText = `${page}/${Math.max(page, this.maxPage)}`
  }

  gotoPreviousStep() {
    this.currentPage--
    this.layoutDataBus.onChangePPTPage.setValue('gotoPreviousStep')
  }

  gotoNextStep() {
    if (this.currentPage >= this.teacherMaxPage) {
      // 不允许翻页超过讲师曾经翻过的最大页
      return
    }
    this.currentPage++
    this.layoutDataBus.onChangePPTPage.setValue('gotoNextStep')
  }

  goBackTeacherPage() {
    this.layoutDataBus.onChangePPTPage.setValue('pptBtnBack')
  }
}