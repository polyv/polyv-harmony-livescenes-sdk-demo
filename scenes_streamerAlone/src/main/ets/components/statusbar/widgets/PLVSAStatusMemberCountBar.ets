import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, seconds } from '@polyvharmony/media-player-sdk'
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus'
import { PLVSAMemberLayout } from '../../member/PLVSAMemberLayout'

@Component
export struct PLVSAStatusMemberCountBar {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private memberCount: number = 0
  private readonly memberLayoutController = new CustomDialogController({
    builder: PLVSAMemberLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  @State private isViewerRequestRedPointVisible: boolean = false
  @State private isViewerRequestNotifyBarVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.memberManager.channelViewerCount.observe(it => this.memberCount = it)
      .pushTo(this.observers)
    this.sdk.memberManager.onViewerRequestLinkMic.observe(() => {
      const memberLayoutVisible = this.pageDataBus.memberLayoutVisible.value ?? false
      if (!memberLayoutVisible) {
        this.isViewerRequestRedPointVisible = true
        this.isViewerRequestNotifyBarVisible = true
      }
    })
      .pushTo(this.observers)
    this.pageDataBus.memberLayoutVisible.observe((memberLayoutVisible) => {
      if (memberLayoutVisible) {
        this.isViewerRequestRedPointVisible = false
        this.isViewerRequestNotifyBarVisible = false
      }
    }).pushTo(this.observers)
  }

  build() {
    Row() {
      Image($r('app.media.plvsa_status_bar_member_count_icon'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
      Row() {
        Text(this.memberCount.toString())
          .fontColor('#FFFFFF')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
        Circle()
          .id('plvsa_member_button_new_viewer_request_red_point')
          .width(6)
          .height(6)
          .fill('#FF3B30')
          .visibility(this.isViewerRequestRedPointVisible ? Visibility.Visible : Visibility.Hidden)
          .margin({
            left: -2
          })
      }
      .alignItems(VerticalAlign.Top)
      .margin({
        left: 4
      })
    }
    .backgroundColor('#33000000')
    .borderRadius(18)
    .padding({
      left: 10,
      right: 10,
      top: 8,
      bottom: 8
    })
    .bindPopup(this.isViewerRequestNotifyBarVisible, {
      builder: () => {
        this.linkmicNewRequestNotifyBarPopup()
      },
      placement: Placement.Bottom,
      popupColor: '#66000000',
      backgroundBlurStyle: BlurStyle.NONE,
      radius: 20,
      onStateChange: (e) => {
        this.isViewerRequestNotifyBarVisible = e.isVisible
      }
    })
    .onClick(() => {
      this.memberLayoutController.open()
    })
  }

  @Builder
  private linkmicNewRequestNotifyBarPopup() {
    PLVSALinkMicNewRequestNotifyBar({
      onHide: () => {
        this.isViewerRequestNotifyBarVisible = false
      },
      onOpenMemberLayout: () => {
        this.memberLayoutController.open()
      }
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSALinkMicNewRequestNotifyBar {
  onHide: () => void = lateInit()
  onOpenMemberLayout: () => void = lateInit()
  autoHideTimeoutId: number | undefined = undefined

  aboutToAppear(): void {
    this.autoHideTimeoutId = setTimeout(() => {
      this.onHide()
    }, seconds(10).toMillis())
  }

  build() {
    Row() {
      Image($r('app.media.plvsa_linkmic_new_request_icon'))
        .width(18)
        .height(18)
      Text($r('app.string.plvsa_linkmic_new_request_hint_text'))
        .fontSize(14)
        .fontColor('#F0F1F5')
        .margin({
          left: 5
        })
      Text($r('app.string.plvsa_linkmic_new_request_check_text'))
        .width(50)
        .height(24)
        .textAlign(TextAlign.Center)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .borderRadius(16)
        .linearGradient({
          angle: 0,
          colors: [
            ['#0080FF', 0],
            ['#3399FF', 1]
          ]
        })
        .margin({
          left: 12
        })
        .onClick(() => {
          this.onOpenMemberLayout()
        })
    }
    .onClick(() => {
      this.onHide()
    })
    .padding({
      top: 4,
      bottom: 4,
      right: 5,
      left: 12
    })
  }

  aboutToDisappear(): void {
    clearTimeout(this.autoHideTimeoutId)
  }
}