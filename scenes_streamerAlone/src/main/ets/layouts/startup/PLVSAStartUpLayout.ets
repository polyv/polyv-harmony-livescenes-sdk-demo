import {
  PLVCommonConstants,
  PLVLinkMicCameraFacing,
  PLVLiveSceneSDK,
  PLVScheduledTask,
  PLVUserType
} from '@polyvharmony/live-scenes-sdk';
import { Disposable, lateInit, lazy, MutableObserver, seconds } from '@polyvharmony/media-player-sdk';
import { PLVSAPageDataBus, PLVSAStreamerStage } from '../../common/PLVSAPageDataBus';
import { PLVSAMoreBitRateButton } from '../../components/more/widgets/PLVSAMoreBitRateButton';
import { PLVSAMoreCameraFacingButton } from '../../components/more/widgets/PLVSAMoreCameraFacingButton';
import { PLVSAMoreCameraMirrorButton } from '../../components/more/widgets/PLVSAMoreCameraMirrorButton';
import { PLVSAMoreMixLayoutButton } from '../../components/more/widgets/PLVSAMoreMixLayoutButton';
import { PLVSAMoreOrientationButton } from '../../components/more/widgets/PLVSAMoreOrientationButton';
import { PLVSAMoreResolutionRatioButton } from '../../components/more/widgets/PLVSAMoreResolutionRatioButton';
import { router } from '@kit.ArkUI';
import { PLVSAConfirmDialog } from '../../common/widget/PLVSAConfirmDialog';
import { PLVSAMoreLayoutActionSwitcher } from '../../components/more/PLVSAMoreLayout';
import { PLVSAStartUpTitleInputLayout } from './components/PLVSAStartUpTitleInputLayout';
import { PLVSAStartUpSplashImageLayout } from './components/PLVSAStartUpSplashImageLayout';

@Component
export struct PLVSAStartUpLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  private readonly recoverStreamDialog = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      hasTitle: false,
      content: $r('app.string.plvsa_last_stream_not_finish_hint'),
      cancelText: $r('app.string.plvsa_last_stream_not_finish_cancel_recover'),
      confirmText: $r('app.string.plvsa_last_stream_not_finish_confirm_recover'),
      onClickCancel: (controller) => {
        this.sdk.streamerManager.finishStream()
        controller?.close()
      },
      onClickConfirm: (controller) => {
        this.recoverLiveStream()
        controller?.close()
      }
    }),
    autoCancel: false,
    customStyle: true
  })
  @State liveTitle: string = ""
  @State liveTitleInputVisible: boolean = false
  @State countDownLayoutVisible: boolean = false
  @State isPortrait: boolean = true
  @State titleTextWidth: number = 0
  private readonly actionSwitcher = lazy(() => new PLVSAMoreLayoutActionSwitcher(this.sdk))
  private recoverStream: boolean = false
  private countDownHandler: PLVSAStartUpCountDownHandler | null = null
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.liveTitle = this.sdk.channelData.streamerData?.channelName ?? ""
    this.pageDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
    this.checkLastStreamNotFinish()
  }

  private checkLastStreamNotFinish() {
    const isTeacher = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
    const isLastStreamNotFinish = this.sdk.channelData.streamerData?.liveStatus === true
    if (isTeacher && isLastStreamNotFinish) {
      this.recoverStreamDialog.open()
    }
  }

  build() {
    Stack() {
      RelativeContainer() {
        Image($r('app.media.plvsa_startup_back_icon'))
          .id('plvsa_startup_back_icon')
          .width(36)
          .height(36)
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
          })
          .margin({
            left: 24,
            top: 9
          })
          .onClick(() => {
            router.back()
          })

        Row() {
          PLVSAStartUpSplashImageLayout()
            .width(88)
            .height(50)

          Text(this.liveTitle ?? $r('app.string.plvsa_startup_title_placeholder'))
            .constraintSize({
              minWidth: 144,
              maxWidth: this.isPortrait ? 231 : 500
            })
            .maxLines(2)
            .fontColor('#B3FFFFFF')
            .fontSize(18)
            .textAlign(TextAlign.Center)
            .textOverflow({
              overflow: TextOverflow.Ellipsis
            })
            .ellipsisMode(EllipsisMode.END)
            .margin({
              left: 12
            })
            .onAreaChange((oldArea, newArea) => {
              this.titleTextWidth = newArea.width as number
            })
            .onClick(() => {
              if (this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER) {
                this.liveTitleInputVisible = true
              }
            })
        }
        .id('plvsa_startup_title_layout')
        .width(this.titleTextWidth + 120)
        .padding(10)
        .backgroundColor('#33000000')
        .borderRadius(8)
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
        })
        .margin({
          top: 72
        })
        .visibility(this.liveTitleInputVisible ? Visibility.None : Visibility.Visible)

        Flex({
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Center
        }) {
          PLVSAMoreCameraFacingButton({
            iconPadding: 12
          })
            .width(62)
            .padding({
              top: 6,
              bottom: 6
            })

          if (this.actionSwitcher.value.showMirrorButton) {
            PLVSAMoreCameraMirrorButton({
              iconPadding: 12
            })
              .width(62)
              .padding({
                top: 6,
                bottom: 6
              })
          }

          PLVSAMoreBitRateButton({
            iconPadding: 12
          })
            .width(62)
            .padding({
              top: 6,
              bottom: 6
            })

          PLVSAMoreOrientationButton({
            iconPadding: 12
          })
            .width(62)
            .padding({
              top: 6,
              bottom: 6
            })

          if (this.actionSwitcher.value.showMixLayoutButton) {
            PLVSAMoreMixLayoutButton({
              iconPadding: 12
            })
              .width(62)
              .padding({
                top: 6,
                bottom: 6
              })
          }

          if (this.actionSwitcher.value.showResolutionRatioButton && !this.isPortrait) {
            PLVSAMoreResolutionRatioButton({
              iconPadding: 12
            })
              .width(62)
              .padding({
                top: 6,
                bottom: 6
              })
          }
        }
        .id('plvsa_startup_setting_layout')
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          bottom: { anchor: "plvsa_startup_stream_start_button", align: VerticalAlign.Top }
        })
        .padding({
          left: 24,
          right: 24
        })
        .margin({
          bottom: 40
        })

        Button($r('app.string.plvsa_startup_start_live'))
          .id('plvsa_startup_stream_start_button')
          .width(280)
          .height(50)
          .fontColor("#FFFFFF")
          .fontSize(16)
          .backgroundColor("#0080FF")
          .margin({
            bottom: 20
          })
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
          })
          .onClick(() => {
            this.countDownHandler?.startCountDown?.()
          })
      }
      .visibility(this.countDownLayoutVisible ? Visibility.None : Visibility.Visible)
      .width('100%')
      .height('100%')

      PLVSAStartUpTitleInputLayout({
        liveTitle: this.liveTitle,
        isVisible: this.liveTitleInputVisible
      })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
        .hitTestBehavior(HitTestMode.Transparent)

      PLVSAStartUpCountDownLayout({
        callbackHandler: (handler: PLVSAStartUpCountDownHandler | null) => {
          this.countDownHandler = handler
        },
        onCountDownStart: () => {
          this.countDownLayoutVisible = true
        },
        onCountDownFinish: () => {
          this.countDownLayoutVisible = false
          this.startLiveStream()
        },
        onCountDownCancel: () => {
          this.countDownLayoutVisible = false
        }
      })
        .id('plvsa_startup_count_down_layout')
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
  }

  private async recoverLiveStream() {
    await this.pageDataBus.recoverSetting.recoverFromLocal(this.sdk)
    this.countDownHandler?.startCountDown?.()
  }

  private async startLiveStream() {
    this.pageDataBus.streamerStage.setValue(PLVSAStreamerStage.LIVE)
    const originLiveTitle = this.sdk.channelData.streamerData?.channelName
    if (this.liveTitle !== originLiveTitle) {
      await this.sdk.streamerManager.updateChannelName(this.liveTitle)
    }
    await this.sdk.streamerManager.startStream(this.recoverStream)
    this.pageDataBus.recoverSetting.update({
      isPortrait: this.pageDataBus.isPortrait.value,
      bitRateIndex: this.sdk.streamerManager.currentBitRate.value?.index,
      isEnableCamera: this.sdk.linkmicManager.localLinkMicViewer.value?.isVideoEnable.value,
      isFrontCamera: this.sdk.linkmicManager.cameraFacing.value !== PLVLinkMicCameraFacing.BACK
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSAStartUpCountDownLayout {
  callbackHandler?: (handler: PLVSAStartUpCountDownHandler | null) => void
  onCountDownStart?: () => void
  onCountDownFinish?: () => void
  onCountDownCancel?: () => void
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State visible: boolean = false
  @State countDownText: string = ""
  private countDown: number = 0
  private countDownTask: PLVScheduledTask | undefined = undefined
  private onBackPressDisposable: Disposable | undefined = undefined

  aboutToAppear(): void {
    const handler = new PLVSAStartUpCountDownHandler()
    handler.startCountDown = () => {
      this.startCountDown()
    }
    this.callbackHandler?.(handler)
    this.onBackPressDisposable = this.pageDataBus.onBackPressHandler.register(10, () => this.onBackPress())
  }

  build() {
    if (this.visible) {
      Stack() {
        Text(this.countDownText)
          .width(100)
          .height(100)
          .borderRadius(100)
          .backgroundColor("#66000000")
          .fontColor('#FFFFFF')
          .fontSize(48)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#99000000')
    }
  }

  private startCountDown() {
    if (this.countDownTask !== undefined) {
      this.onCountDownCancel?.()
      this.stopCountDown()
    }
    this.countDown = 4
    this.countDownTask = new PLVScheduledTask(() => {
      this.countDown -= 1
      this.countDownText = this.countDown.toString()
      this.visible = this.countDown > 0
      if (this.countDown <= 0) {
        this.stopCountDown()
        this.onCountDownFinish?.()
      }
    }, 0, seconds(1).toMillis())
    this.onCountDownStart?.()
    this.countDownTask.start()
  }

  private stopCountDown() {
    this.countDownTask?.cancel()
    this.countDownTask = undefined
  }

  onBackPress(): boolean {
    if (this.visible) {
      this.stopCountDown()
      this.visible = false
      this.onCountDownCancel?.()
      return true
    }
    return false
  }

  aboutToDisappear(): void {
    this.callbackHandler?.(null)
    this.onBackPressDisposable?.dispose()
  }
}

class PLVSAStartUpCountDownHandler {
  startCountDown?: () => void
}