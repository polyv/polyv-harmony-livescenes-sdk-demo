import {
  PLVLinkMicMode,
  PLVLinkMicViewer,
  PLVLiveSceneSDK,
  PLVSocketUserBean,
  PLVUserType
} from '@polyvharmony/live-scenes-sdk';
import { isTextEmpty, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus';
import { PLVSAConfirmDialog } from '../../../common/widget/PLVSAConfirmDialog';
import { display } from '@kit.ArkUI';

@CustomDialog
export struct PLVSALinkMicMemberControlDialog {
  controller?: CustomDialogController = lateInit()
  viewer: PLVLinkMicViewer = lateInit()

  build() {
    if (this.isPortrait()) {
      PLVSALinkMicMemberControlDialogPort({
        controller: this.controller,
        viewer: this.viewer
      })
    } else {
      PLVSALinkMicMemberControlDialogLand({
        controller: this.controller,
        viewer: this.viewer
      })
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSALinkMicMemberControlDialogPort {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  controller?: CustomDialogController = lateInit()
  viewer: PLVLinkMicViewer = lateInit()
  private switcher: PLVSALinkMicMemberControlActionSwitcher | undefined = undefined
  @State private viewerName: string = ""
  @State private isCameraEnable: boolean = false
  @State private isMicrophoneEnable: boolean = false
  @State private isMainView: boolean = false
  private controlActionDialog: CustomDialogController | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.switcher = new PLVSALinkMicMemberControlActionSwitcher(this.sdk, this.viewer)
    this.viewer.viewerName.observe(it => this.viewerName = it ?? "").pushTo(this.observers)
    this.viewer.isVideoEnable.observe(it => this.isCameraEnable = it).pushTo(this.observers)
    this.viewer.isAudioEnable.observe(it => this.isMicrophoneEnable = it).pushTo(this.observers)
    this.sdk.linkmicManager.channelMainViewLinkMicId.observe(it => this.isMainView = this.viewer.linkmicId === it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Stack() {
        Image(this.viewer.viewerAvatar)
          .width(66)
          .height(66)
          .alt($r('app.media.plvsa_member_default_avatar_student'))
          .borderColor('#FFFFFF')
          .borderWidth(1)
          .borderRadius(66)

        if (!isTextEmpty(this.viewer.viewerActor)) {
          Text(this.viewer.viewerActor)
            .height(18)
            .constraintSize({
              maxWidth: 42
            })
            .maxLines(1)
            .textOverflow({
              overflow: TextOverflow.Ellipsis
            })
            .ellipsisMode(EllipsisMode.END)
            .textAlign(TextAlign.Center)
            .fontColor('#F0F1F5')
            .fontSize(12)
            .padding({
              left: 3,
              right: 3
            })
            .borderRadius(15)
            .linearGradient({
              angle: 90,
              colors: this.viewerActorBackground()
            })
            .translate({
              y: 4
            })
        }
      }
      .height(48)
      .alignContent(Alignment.Bottom)

      Text(this.viewerName)
        .fontColor('#F0F1F5')
        .fontSize(14)
        .margin({
          top: 14
        })
        .maxLines(1)

      Divider()
        .height(1)
        .color('#19ffffff')
        .margin({
          left: 24,
          right: 24,
          top: 24
        })

      List() {
        if (this.switcher?.showCameraControl) {
          ListItem() {
            MemberControlAction({
              icon: this.isCameraEnable ? $r('app.media.plvsa_more_camera_enable') : $r('app.media.plvsa_more_camera_disable'),
              name: $r('app.string.plvsa_more_camera')
            }).onClick(() => this.onClickCamera())
          }
        }

        if (this.switcher?.showMicrophoneControl) {
          ListItem() {
            MemberControlAction({
              icon: this.isMicrophoneEnable ? $r('app.media.plvsa_more_microphone_enable') : $r('app.media.plvsa_more_microphone_disable'),
              name: $r('app.string.plvsa_more_microphone')
            }).onClick(() => this.onClickMicrophone())
          }
        }

        if (this.switcher?.showHangupButton) {
          ListItem() {
            MemberControlAction({
              icon: $r('app.media.plvsa_linkmic_member_control_hang_up_linkmic'),
              name: $r('app.string.plvsa_linkmic_member_control_hang_up_linkmic')
            }).onClick(() => this.onClickHangup())
          }
        }

        if (this.switcher?.showSpeakerControl) {
          ListItem() {
            MemberControlAction({
              icon: $r('app.media.plvsa_linkmic_speaker_icon'),
              name: this.isMainView ? $r('app.string.plvsa_member_more_withdraw_speaker_permission') : $r('app.string.plvsa_member_more_grant_speaker_permission')
            }).onClick(() => this.onClickSpeaker())
          }
        }

        ListItem() {
          MemberControlAction({
            icon: $r('app.media.plvsa_linkmic_member_control_fullscreen_icon'),
            name: $r('app.string.plvsa_linkmic_member_control_full_screen')
          }).onClick(() => this.onClickFullScreen())
        }
      }
      .width('100%')
      .listDirection(Axis.Vertical)
      .alignListItem(ListItemAlign.Center)
      .lanes(4)
      .margin({
        top: 24
      })

    }
    .id('plvsa_linkmic_member_control_layout_content')
    .width('100%')
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
    .padding({
      bottom: 18
    })
  }

  private viewerActorBackground(): [ResourceColor, number][] {
    const viewerType = this.viewer.viewerType
    if (viewerType === undefined) {
      return []
    }
    const linear = (start: ResourceColor, end: ResourceColor): [ResourceColor, number][] => [[start, 0], [end, 1]]
    switch (viewerType) {
      case PLVUserType.USERTYPE_TEACHER:
        return linear('#FFA336', '#FFB95A')
      case PLVUserType.USERTYPE_ASSISTANT:
        return linear('#397ffe', '#73a1fe')
      case PLVUserType.USERTYPE_MANAGER:
        return linear('#32B6BF', '#35C4CF')
      case PLVUserType.USERTYPE_GUEST:
      default:
        return linear('#FF2851', '#FE3182')
    }
  }

  private onClickCamera() {
    this.sdk.linkmicManager.setViewerEnableCamera(this.viewer.viewerId!, !this.isCameraEnable)
    this.controller?.close()
  }

  private onClickMicrophone() {
    this.sdk.linkmicManager.setViewerEnableMicrophone(this.viewer.viewerId!, !this.isMicrophoneEnable)
    this.controller?.close()
  }

  private onClickHangup() {
    this.controlActionDialog = new CustomDialogController({
      builder: PLVSAConfirmDialog({
        title: $r('app.string.plvsa_linkmic_member_control_hang_up_linkmic_confirm_title'),
        hasContent: false,
        onClickConfirm: (controller) => {
          this.sdk.linkmicManager.hangupViewerLinkMic(this.viewer.viewerId!)
          controller?.close()
          this.controller?.close()
        }
      }),
      customStyle: true
    })
    this.controlActionDialog.open()
  }

  private onClickSpeaker() {
    const mainViewLinkMicId = this.sdk.linkmicManager.channelMainViewLinkMicId.value
    const channelHasOtherSpeaker = mainViewLinkMicId !== undefined && mainViewLinkMicId !== this.sdk.channelData.loginChannelId
    if (this.isMainView) {
      // 移除主讲
      this.controlActionDialog = new CustomDialogController({
        builder: PLVSAConfirmDialog({
          title: $r('app.string.plvsa_linkmic_member_control_withdraw_speaker_confirm_title'),
          content: $r('app.string.plvsa_linkmic_member_control_withdraw_speaker_confirm_content'),
          onClickConfirm: (controller) => {
            this.sdk.linkmicManager.revokeSpeaker(this.viewer.viewerId!)
            controller?.close()
            this.controller?.close()
          }
        }),
        customStyle: true
      })
      this.controlActionDialog.open()
    } else if (channelHasOtherSpeaker) {
      // 转移主讲
      this.controlActionDialog = new CustomDialogController({
        builder: PLVSAConfirmDialog({
          title: $r('app.string.plvsa_linkmic_member_control_grant_speaker_confirm_title'),
          content: $r('app.string.plvsa_linkmic_member_control_grant_speaker_confirm_content'),
          onClickConfirm: (controller) => {
            this.sdk.linkmicManager.grantSpeaker(this.viewer.viewerId!)
            controller?.close()
            this.controller?.close()
          }
        }),
        customStyle: true
      })
      this.controlActionDialog.open()
    } else {
      // 直接授予主讲
      this.sdk.linkmicManager.grantSpeaker(this.viewer.viewerId!)
      this.controller?.close()
    }
  }

  private onClickFullScreen() {
    this.pageDataBus.linkmicFullScreenViewer.setValue(this.viewer)
    this.controller?.close()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSALinkMicMemberControlDialogLand {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  controller?: CustomDialogController = lateInit()
  viewer: PLVLinkMicViewer = lateInit()
  private switcher: PLVSALinkMicMemberControlActionSwitcher | undefined = undefined
  @State private viewerName: string = ""
  @State private isCameraEnable: boolean = false
  @State private isMicrophoneEnable: boolean = false
  @State private isMainView: boolean = false
  private controlActionDialog: CustomDialogController | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.switcher = new PLVSALinkMicMemberControlActionSwitcher(this.sdk, this.viewer)
    this.viewer.viewerName.observe(it => this.viewerName = it ?? "").pushTo(this.observers)
    this.viewer.isVideoEnable.observe(it => this.isCameraEnable = it).pushTo(this.observers)
    this.viewer.isAudioEnable.observe(it => this.isMicrophoneEnable = it).pushTo(this.observers)
    this.sdk.linkmicManager.channelMainViewLinkMicId.observe(it => this.isMainView = this.viewer.linkmicId === it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Stack() {
        Image(this.viewer.viewerAvatar)
          .width(66)
          .height(66)
          .alt($r('app.media.plvsa_member_default_avatar_student'))
          .borderColor('#FFFFFF')
          .borderWidth(1)
          .borderRadius(66)

        if (!isTextEmpty(this.viewer.viewerActor)) {
          Text(this.viewer.viewerActor)
            .height(18)
            .constraintSize({
              maxWidth: 42
            })
            .maxLines(1)
            .textOverflow({
              overflow: TextOverflow.Ellipsis
            })
            .ellipsisMode(EllipsisMode.END)
            .textAlign(TextAlign.Center)
            .fontColor('#F0F1F5')
            .fontSize(12)
            .padding({
              left: 3,
              right: 3
            })
            .borderRadius(15)
            .linearGradient({
              angle: 90,
              colors: this.viewerActorBackground()
            })
            .translate({
              y: 4
            })
        }
      }
      .height(66)
      .alignContent(Alignment.Bottom)
      .margin({
        top: 32
      })

      Text(this.viewerName)
        .fontColor('#F0F1F5')
        .fontSize(14)
        .margin({
          top: 14
        })
        .maxLines(1)

      Divider()
        .height(1)
        .color('#19ffffff')
        .margin({
          left: 24,
          right: 24,
          top: 24
        })

      Grid() {
        if (this.switcher?.showCameraControl) {
          GridItem() {
            MemberControlAction({
              icon: this.isCameraEnable ? $r('app.media.plvsa_more_camera_enable') : $r('app.media.plvsa_more_camera_disable'),
              name: $r('app.string.plvsa_more_camera')
            }).onClick(() => this.onClickCamera())
          }
        }

        if (this.switcher?.showMicrophoneControl) {
          GridItem() {
            MemberControlAction({
              icon: this.isMicrophoneEnable ? $r('app.media.plvsa_more_microphone_enable') : $r('app.media.plvsa_more_microphone_disable'),
              name: $r('app.string.plvsa_more_microphone')
            }).onClick(() => this.onClickMicrophone())
          }
        }

        if (this.switcher?.showHangupButton) {
          GridItem() {
            MemberControlAction({
              icon: $r('app.media.plvsa_linkmic_member_control_hang_up_linkmic'),
              name: $r('app.string.plvsa_linkmic_member_control_hang_up_linkmic')
            }).onClick(() => this.onClickHangup())
          }
        }

        if (this.switcher?.showSpeakerControl) {
          GridItem() {
            MemberControlAction({
              icon: $r('app.media.plvsa_linkmic_speaker_icon'),
              name: this.isMainView ? $r('app.string.plvsa_member_more_withdraw_speaker_permission') : $r('app.string.plvsa_member_more_grant_speaker_permission')
            }).onClick(() => this.onClickSpeaker())
          }
        }

        GridItem() {
          MemberControlAction({
            icon: $r('app.media.plvsa_linkmic_member_control_fullscreen_icon'),
            name: $r('app.string.plvsa_linkmic_member_control_full_screen')
          }).onClick(() => this.onClickFullScreen())
        }
      }
      .width('100%')
      .layoutWeight(1)
      .columnsTemplate('1fr 1fr 1fr')
      .margin({
        top: 24
      })

    }
    .id('plvsa_linkmic_member_control_layout_content')
    .width(300)
    .height('100%')
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      bottomLeft: 16
    })
  }

  private viewerActorBackground(): [ResourceColor, number][] {
    const viewerType = this.viewer.viewerType
    if (viewerType === undefined) {
      return []
    }
    const linear = (start: ResourceColor, end: ResourceColor): [ResourceColor, number][] => [[start, 0], [end, 1]]
    switch (viewerType) {
      case PLVUserType.USERTYPE_TEACHER:
        return linear('#FFA336', '#FFB95A')
      case PLVUserType.USERTYPE_ASSISTANT:
        return linear('#397ffe', '#73a1fe')
      case PLVUserType.USERTYPE_MANAGER:
        return linear('#32B6BF', '#35C4CF')
      case PLVUserType.USERTYPE_GUEST:
      default:
        return linear('#FF2851', '#FE3182')
    }
  }

  private onClickCamera() {
    this.sdk.linkmicManager.setViewerEnableCamera(this.viewer.viewerId!, !this.isCameraEnable)
    this.controller?.close()
  }

  private onClickMicrophone() {
    this.sdk.linkmicManager.setViewerEnableMicrophone(this.viewer.viewerId!, !this.isMicrophoneEnable)
    this.controller?.close()
  }

  private onClickHangup() {
    this.controlActionDialog = new CustomDialogController({
      builder: PLVSAConfirmDialog({
        title: $r('app.string.plvsa_linkmic_member_control_hang_up_linkmic_confirm_title'),
        hasContent: false,
        onClickConfirm: (controller) => {
          this.sdk.linkmicManager.hangupViewerLinkMic(this.viewer.viewerId!)
          controller?.close()
          this.controller?.close()
        }
      }),
      customStyle: true
    })
    this.controlActionDialog.open()
  }

  private onClickSpeaker() {
    const mainViewLinkMicId = this.sdk.linkmicManager.channelMainViewLinkMicId.value
    const channelHasOtherSpeaker = mainViewLinkMicId !== undefined && mainViewLinkMicId !== this.sdk.channelData.loginChannelId
    if (this.isMainView) {
      // 移除主讲
      this.controlActionDialog = new CustomDialogController({
        builder: PLVSAConfirmDialog({
          title: $r('app.string.plvsa_linkmic_member_control_withdraw_speaker_confirm_title'),
          content: $r('app.string.plvsa_linkmic_member_control_withdraw_speaker_confirm_content'),
          onClickConfirm: (controller) => {
            this.sdk.linkmicManager.revokeSpeaker(this.viewer.viewerId!)
            controller?.close()
            this.controller?.close()
          }
        }),
        customStyle: true
      })
      this.controlActionDialog.open()
    } else if (channelHasOtherSpeaker) {
      // 转移主讲
      this.controlActionDialog = new CustomDialogController({
        builder: PLVSAConfirmDialog({
          title: $r('app.string.plvsa_linkmic_member_control_grant_speaker_confirm_title'),
          content: $r('app.string.plvsa_linkmic_member_control_grant_speaker_confirm_content'),
          onClickConfirm: (controller) => {
            this.sdk.linkmicManager.grantSpeaker(this.viewer.viewerId!)
            controller?.close()
            this.controller?.close()
          }
        }),
        customStyle: true
      })
      this.controlActionDialog.open()
    } else {
      // 直接授予主讲
      this.sdk.linkmicManager.grantSpeaker(this.viewer.viewerId!)
      this.controller?.close()
    }
  }

  private onClickFullScreen() {
    this.pageDataBus.linkmicFullScreenViewer.setValue(this.viewer)
    this.controller?.close()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct MemberControlAction {
  icon: Resource = lateInit()
  name: Resource = lateInit()

  build() {
    Column() {
      Image(this.icon)
        .width(30)
        .height(30)
        .objectFit(ImageFit.Contain)
      Text(this.name)
        .fontColor('#99ffffff')
        .fontSize(14)
        .margin({
          top: 8
        })
    }
    .padding({
      top: 6,
      bottom: 6
    })
    .margin({
      top: 6,
      bottom: 6
    })
  }
}

export class PLVSALinkMicMemberControlActionSwitcher {
  readonly canShowMemberControlDialog: boolean
  readonly showCameraControl: boolean
  readonly showMicrophoneControl: boolean
  readonly showHangupButton: boolean
  readonly showSpeakerControl: boolean

  constructor(
    sdk: PLVLiveSceneSDK,
    viewer: PLVLinkMicViewer
  ) {
    const localIsTeacher = sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
    const viewerIsSpecialUserType = PLVSocketUserBean.isSpecialType(viewer.viewerType)
    const linkmicMode = sdk.linkmicManager.channelLinkMicMode.value ?? PLVLinkMicMode.AUDIO

    this.canShowMemberControlDialog = !localIsTeacher || !viewer.isMyself
    this.showCameraControl = localIsTeacher && !viewer.isMyself && (linkmicMode === PLVLinkMicMode.VIDEO || viewerIsSpecialUserType)
    this.showMicrophoneControl = localIsTeacher && !viewer.isMyself
    this.showHangupButton = localIsTeacher && !viewer.isMyself
    this.showSpeakerControl = localIsTeacher && !viewer.isMyself
  }
}