import { isLiteralTrue, lateInit, lazy } from '@polyvharmony/media-player-sdk';
import { display } from '@kit.ArkUI';
import { PLVSAMoreCameraEnableButton } from './widgets/PLVSAMoreCameraEnableButton';
import { PLVSAMoreMicrophoneEnableButton } from './widgets/PLVSAMoreMicrophoneEnableButton';
import { PLVSAMoreCameraFacingButton } from './widgets/PLVSAMoreCameraFacingButton';
import { PLVSAMoreCameraMirrorButton } from './widgets/PLVSAMoreCameraMirrorButton';
import { PLVSAMoreBitRateButton } from './widgets/PLVSAMoreBitRateButton';
import { PLVSAMoreMixLayoutButton } from './widgets/PLVSAMoreMixLayoutButton';
import { PLVSAMoreCloseRoomButton } from './widgets/PLVSAMoreCloseRoomButton';
import { PLVSAMoreHangupAllLinkMicButton } from './widgets/PLVSAMoreHangupAllLinkMicButton';
import { PLVSAMoreAllowLinkMicButton } from './widgets/PLVSAMoreAllowLinkMicButton';
import { PLVSAMoreLinkMicSettingButton } from './widgets/PLVSAMoreLinkMicSettingButton';
import { PLVSAMorePushDowngradeButton } from './widgets/PLVSAMorePushDowngradeButton';
import { PLVLinkMicRTCType, PLVLiveSceneSDK, PLVUserType } from '@polyvharmony/live-scenes-sdk';
import { PLVSAMoreShareButton } from './widgets/PLVSAMoreShareButton';

@CustomDialog
export struct PLVSAMoreLayout {
  controller: CustomDialogController = lateInit()

  build() {
    if (this.isPortrait()) {
      PLVSAMoreLayoutPort({
        controller: this.controller
      })
    } else {
      PLVSAMoreLayoutLand({
        controller: this.controller
      })
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSAMoreLayoutPort {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly switcher = lazy(() => new PLVSAMoreLayoutActionSwitcher(this.sdk))

  build() {
    Column() {
      Text($r('app.string.plvsa_more_layout_title'))
        .fontColor('#F0F1F5')
        .fontSize(18)
        .margin({
          left: 25,
          top: 32
        })
      Scroll() {
        Grid() {
          GridItem() {
            PLVSAMoreCameraEnableButton()
          }

          GridItem() {
            PLVSAMoreMicrophoneEnableButton()
          }

          GridItem() {
            PLVSAMoreCameraFacingButton()
          }

          if (this.switcher.value.showMirrorButton) {
            GridItem() {
              PLVSAMoreCameraMirrorButton()
            }
          }

          GridItem() {
            PLVSAMoreBitRateButton({
              onClicked: (origin) => {
                this.controller.close()
                origin()
              }
            })
          }

          if (this.switcher.value.showCloseRoomButton) {
            GridItem() {
              PLVSAMoreCloseRoomButton()
            }
          }

          if (this.switcher.value.showShareButton) {
            GridItem() {
              PLVSAMoreShareButton({
                onClicked: (origin) => {
                  this.controller.close()
                  origin()
                }
              })
            }
          }

          GridItem() {
            PLVSAMorePushDowngradeButton({
              onClicked: (origin) => {
                this.controller.close()
                origin()
              }
            })
          }

          if (this.switcher.value.showAllowLinkMicButton) {
            GridItem() {
              PLVSAMoreAllowLinkMicButton()
            }
          }

          if (this.switcher.value.showHangupAllLinkMicButton) {
            GridItem() {
              PLVSAMoreHangupAllLinkMicButton()
            }
          }

          if (this.switcher.value.showLinkMicSettingButton) {
            GridItem() {
              PLVSAMoreLinkMicSettingButton({
                onClicked: (origin) => {
                  this.controller.close()
                  origin()
                }
              })
            }
          }

          if (this.switcher.value.showMixLayoutButton) {
            GridItem() {
              PLVSAMoreMixLayoutButton({
                onClicked: (origin) => {
                  this.controller.close()
                  origin()
                }
              })
            }
          }
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .rowsGap(12)
        .padding({
          left: 25,
          right: 25
        })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .margin({
        top: 16
      })
    }
    .width('100%')
    .height(270)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
  }
}

@Component
struct PLVSAMoreLayoutLand {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly switcher = lazy(() => new PLVSAMoreLayoutActionSwitcher(this.sdk))

  build() {
    Column() {
      Text($r('app.string.plvsa_more_layout_title'))
        .fontColor('#F0F1F5')
        .fontSize(18)
        .margin({
          left: 25,
          top: 32
        })
      Scroll() {
        Grid() {
          GridItem() {
            PLVSAMoreCameraEnableButton()
          }

          GridItem() {
            PLVSAMoreMicrophoneEnableButton()
          }

          GridItem() {
            PLVSAMoreCameraFacingButton()
          }

          if (this.switcher.value.showMirrorButton) {
            GridItem() {
              PLVSAMoreCameraMirrorButton()
            }
          }

          GridItem() {
            PLVSAMoreBitRateButton({
              onClicked: (origin) => {
                this.controller.close()
                origin()
              }
            })
          }

          if (this.switcher.value.showCloseRoomButton) {
            GridItem() {
              PLVSAMoreCloseRoomButton()
            }
          }

          if (this.switcher.value.showShareButton) {
            GridItem() {
              PLVSAMoreShareButton({
                onClicked: (origin) => {
                  this.controller.close()
                  origin()
                }
              })
            }
          }

          GridItem() {
            PLVSAMorePushDowngradeButton({
              onClicked: (origin) => {
                this.controller.close()
                origin()
              }
            })
          }

          if (this.switcher.value.showAllowLinkMicButton) {
            GridItem() {
              PLVSAMoreAllowLinkMicButton()
            }
          }

          if (this.switcher.value.showHangupAllLinkMicButton) {
            GridItem() {
              PLVSAMoreHangupAllLinkMicButton()
            }
          }

          if (this.switcher.value.showLinkMicSettingButton) {
            GridItem() {
              PLVSAMoreLinkMicSettingButton({
                onClicked: (origin) => {
                  this.controller.close()
                  origin()
                }
              })
            }
          }

          if (this.switcher.value.showMixLayoutButton) {
            GridItem() {
              PLVSAMoreMixLayoutButton({
                onClicked: (origin) => {
                  this.controller.close()
                  origin()
                }
              })
            }
          }
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(12)
        .padding({
          left: 25,
          right: 25
        })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .margin({
        top: 16
      })
    }
    .width(240)
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      bottomLeft: 16
    })
  }
}

export class PLVSAMoreLayoutActionSwitcher {
  private readonly sdk: PLVLiveSceneSDK
  readonly showCloseRoomButton: boolean
  readonly showShareButton: boolean
  readonly showAllowLinkMicButton: boolean
  readonly showHangupAllLinkMicButton: boolean
  readonly showLinkMicSettingButton: boolean
  readonly showMixLayoutButton: boolean
  readonly showResolutionRatioButton: boolean
  readonly showMirrorButton: boolean

  constructor(sdk: PLVLiveSceneSDK) {
    this.sdk = sdk
    const isTeacher = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
    const isLinkMicStrategyV2 = this.sdk.linkmicManager.isLinkMicStrategyV2.value ?? false
    const isMirrorSupport = this.sdk.channelData.liveDetail?.rtcType != PLVLinkMicRTCType.TRTC

    this.showCloseRoomButton = isTeacher
    this.showShareButton = isLiteralTrue(this.sdk.channelData.liveDetail?.pushSharingEnabled)
    this.showAllowLinkMicButton = isTeacher && isLinkMicStrategyV2
    this.showHangupAllLinkMicButton = isTeacher
    this.showLinkMicSettingButton = isTeacher && isLinkMicStrategyV2
    this.showMixLayoutButton = isTeacher
    this.showResolutionRatioButton = isTeacher && isLiteralTrue(this.sdk.channelData.streamerData?.appWebStartResolutionRatioEnabled)
    this.showMirrorButton = isMirrorSupport
  }
}