import {
  PLVLinkMicMode,
  PLVLinkMicState,
  PLVLiveSceneSDK,
  PLVMemberChannelViewer,
  PLVSocketUserBean,
  PLVStreamerState,
  PLVUserType
} from '@polyvharmony/live-scenes-sdk';
import {
  DerivedState,
  isLiteralTrue,
  isTextBlank,
  isTextEmpty,
  lateInit,
  MutableObserver,
  PLVMediaPlayerAppContext
} from '@polyvharmony/media-player-sdk';
import { CircleShape } from '@kit.ArkUI';
import { PLVSAConfirmDialog } from '../../../common/widget/PLVSAConfirmDialog';

@Component
export struct PLVSAMemberListItem {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  viewer: PLVMemberChannelViewer = lateInit()
  @State actor: string | undefined = undefined
  @State nickName: string = ""
  @State nickLabelMyself: string = ""
  @State isChannelOpenLinkMic: boolean = false
  @State channelLinkMicMode: PLVLinkMicMode = PLVLinkMicMode.VIDEO
  @State streamState: PLVStreamerState = PLVStreamerState.NOT_START
  @State linkmicState: PLVLinkMicState = PLVLinkMicState.NoLinkMic
  @State isVideoEnable: boolean = false
  @State isAudioEnable: boolean = false
  @State isSpeaker: boolean = false
  @State isBan: boolean = false
  @State morePopupVisible: boolean = false
  private readonly hangupLinkMicDialogController = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      title: $r('app.string.plvsa_member_hang_up_linkmic_confirm_title'),
      hasContent: false,
      onClickConfirm: (controller) => {
        this.sdk.linkmicManager.hangupViewerLinkMic(this.viewer.viewerId)
        controller?.close()
      }
    }),
    customStyle: true
  })
  private readonly kickViewerDialogController = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      title: $r('app.string.plvsa_member_kick_confirm_title', this.viewer.viewerName.value),
      content: $r('app.string.plvsa_member_kick_confirm_content'),
      onClickConfirm: (controller) => {
        this.sdk.memberManager.kickViewer(this.viewer.viewerId)
        controller?.close()
      }
    }),
    customStyle: true
  })
  private readonly banViewerDialogController = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      title: $r('app.string.plvsa_member_ban_confirm_title', this.viewer.viewerName.value),
      hasContent: false,
      onClickConfirm: (controller) => {
        this.sdk.memberManager.banViewer(this.viewer.viewerId)
        controller?.close()
      }
    }),
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const isSpecialUserType = PLVSocketUserBean.isSpecialType(this.viewer.viewerType)
    this.actor = isSpecialUserType ? this.viewer.viewerActor : undefined
    this.nickLabelMyself = this.viewer.isMyself ? PLVMediaPlayerAppContext.getString($r('app.string.plvsa_chat_me'), "", "") : ""
    this.viewer.viewerName.observe(it => this.nickName = it ?? "").pushTo(this.observers)
    this.viewer.linkmicState.observe(it => this.linkmicState = it).pushTo(this.observers)
    this.viewer.ban.observe(it => this.isBan = it).pushTo(this.observers)
    this.sdk.linkmicManager.channelAllowRequestHandsUpLinkMic.observe(it => this.isChannelOpenLinkMic = it)
      .pushTo(this.observers)
    this.sdk.linkmicManager.channelLinkMicMode.observe(it => this.channelLinkMicMode = it)
      .pushTo(this.observers)
    this.sdk.streamerManager.streamerState.observe(it => this.streamState = it)
      .pushTo(this.observers)
    this.sdk.linkmicManager.channelMainViewLinkMicId.observe((mainViewLinkMicId) => {
      this.isSpeaker = this.viewer.linkmicId !== undefined && this.viewer.linkmicId === mainViewLinkMicId
    }).pushTo(this.observers)
    const stateVideoEnable = new DerivedState(() => {
      const linkmicViewer = (this.sdk.linkmicManager.channelLinkMicViewers.value ?? [])
        .find(linkmicViewer => linkmicViewer.linkmicId === this.viewer.linkmicId)
      return linkmicViewer?.isVideoEnable.value ?? false
    })
    stateVideoEnable.observe(it => this.isVideoEnable = it).pushTo(this.observers)
    const stateAudioEnable = new DerivedState(() => {
      const linkmicViewer = (this.sdk.linkmicManager.channelLinkMicViewers.value ?? [])
        .find(linkmicViewer => linkmicViewer.linkmicId === this.viewer.linkmicId)
      return linkmicViewer?.isAudioEnable.value ?? false
    })
    stateAudioEnable.observe(it => this.isAudioEnable = it).pushTo(this.observers)
  }

  build() {
    Row() {
      // 头像
      Stack() {
        Image(this.viewerAvatar())
          .width(44)
          .height(44)
          .clipShape(new CircleShape({
            width: 44,
            height: 44
          }))
        // 禁言角标
        if (this.isBan) {
          Image($r('app.media.plvsa_member_list_item_ban_chat_icon'))
            .width(20)
            .height(20)
            .translate({
              x: 4
            })
        }
      }
      .width(44)
      .height(44)
      .alignContent(Alignment.BottomEnd)
      .margin({
        right: 12
      })

      // 头衔
      if (!isTextEmpty(this.actor)) {
        Text(this.actor)
          .height(18)
          .constraintSize({
            minWidth: 42
          })
          .fontSize(11)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .padding({
            left: 3,
            right: 3
          })
          .borderRadius(15)
          .linearGradient({
            angle: 90,
            colors: this.viewerActorBackground()
          })
          .margin({
            right: 8
          })
      }

      // 昵称
      Text(this.nickName + this.nickLabelMyself)
        .fontColor('#F0F1F5')
        .fontSize(14)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
        .ellipsisMode(EllipsisMode.END)

      // 申请连麦举手图标
      if (this.isHandsUpIconVisible()) {
        Image($r('app.media.plvsa_member_linkmic_hand_up_icon'))
          .width(20)
          .height(20)
          .margin({
            right: 8
          })
      }

      // 连麦控制图标
      if (this.isLinkMicButtonVisible()) {
        Image(this.linkmicButtonIcon())
          .width(32)
          .height(32)
          .onClick(() => this.onClickLinkMicButton())
      }

      // 更多菜单按钮
      if (this.isMoreButtonVisible()) {
        Image($r('app.media.plvsa_member_more_icon'))
          .width(32)
          .height(32)
          .margin({
            left: 20
          })
          .onClick(() => this.morePopupVisible = true)
          .bindPopup(this.morePopupVisible, {
            builder: this.moreButtonPopup,
            placement: Placement.Top,
            backgroundBlurStyle: BlurStyle.NONE,
            popupColor: '#212121',
            radius: 16,
            onStateChange: (event) => {
              this.morePopupVisible = event.isVisible
            }
          })
      }
    }
    .width('100%')
    .height(68)
  }

  private viewerAvatar(): string | Resource {
    if (!isTextBlank(this.viewer.viewerAvatar)) {
      return this.viewer.viewerAvatar as string
    }
    const isSpecialUser = PLVSocketUserBean.isSpecialType(this.viewer.viewerType)
    if (isSpecialUser) {
      return $r('app.media.plvsa_member_default_avatar_teacher')
    } else {
      return $r('app.media.plvsa_member_default_avatar_student')
    }
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

  private isHandsUpIconVisible(): boolean {
    const isMyselfTeacher = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
    const isViewerRequesting = this.linkmicState === PLVLinkMicState.Requesting
    return isMyselfTeacher && isViewerRequesting
  }

  private isLinkMicButtonVisible(): boolean {
    const isMyselfTeacher = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
    const isViewerUserTypeGuest = this.viewer.viewerType === PLVUserType.USERTYPE_GUEST
    const isViewerUserTypeViewer = this.viewer.viewerType === PLVUserType.USERTYPE_VIEWER
    const isLinkMicStrategyV2 = this.sdk.linkmicManager.isLinkMicStrategyV2.value ?? false
    const isChannelAllowInviteLinkMic = isLiteralTrue(this.sdk.channelData.liveDetail?.inviteAudioEnabled)
    const canInviteLinkMicV1 = !isLinkMicStrategyV2
      && isMyselfTeacher
      && (this.isChannelOpenLinkMic || isViewerUserTypeGuest || isViewerUserTypeViewer)
      && (isChannelAllowInviteLinkMic || isViewerUserTypeGuest || isViewerUserTypeViewer)
    const canInviteLinkMicV2 = isLinkMicStrategyV2
      && isMyselfTeacher
      && (isChannelAllowInviteLinkMic || isViewerUserTypeGuest || isViewerUserTypeViewer)
    const canInviteLinkMic = canInviteLinkMicV1 || canInviteLinkMicV2

    if (this.viewer.isMyself || !isMyselfTeacher || this.streamState !== PLVStreamerState.START) {
      return false
    }
    if (this.linkmicState === PLVLinkMicState.NoLinkMic) {
      return canInviteLinkMic
    } else {
      return true
    }
  }

  private linkmicButtonIcon(): Resource {
    switch (this.linkmicState) {
      case PLVLinkMicState.NoLinkMic:
      case PLVLinkMicState.Requesting:
      case PLVLinkMicState.WaitingResponse:
      default:
        return $r('app.media.plvsa_linkmic_button_to_open')
      case PLVLinkMicState.Inviting:
        return $r('app.media.plvsa_linkmic_waiting_response_anim')
      case PLVLinkMicState.Joined:
        return $r('app.media.plvsa_linkmic_button_to_close')
    }
  }

  private isMoreButtonVisible(): boolean {
    const isMyselfTeacher = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
    const isSpecialUserType = PLVSocketUserBean.isSpecialType(this.viewer.viewerType)

    if (this.viewer.isMyself || !isMyselfTeacher) {
      return false
    }
    if (!isSpecialUserType) {
      return true
    } else {
      return this.linkmicState === PLVLinkMicState.Joined
    }
  }

  @Builder
  private moreButtonPopup() {
    Column() {
      // 摄像头控制
      if (this.linkmicState === PLVLinkMicState.Joined && this.channelLinkMicMode === PLVLinkMicMode.VIDEO) {
        Row() {
          Image(this.isVideoEnable ? $r('app.media.plvsa_more_camera_enable') : $r('app.media.plvsa_more_camera_disable'))
            .width(44)
            .height(44)
            .padding(10)
            .objectFit(ImageFit.Contain)
          Text($r('app.string.plvsa_more_camera'))
            .fontSize(14)
            .fontColor('#F0F1F5')
        }
        .onClick(() => this.onClickControlCamera())
      }
      // 麦克风控制
      if (this.linkmicState === PLVLinkMicState.Joined) {
        Row() {
          Image(this.isAudioEnable ? $r('app.media.plvsa_more_microphone_enable') : $r('app.media.plvsa_more_microphone_disable'))
            .width(44)
            .height(44)
            .padding(10)
            .objectFit(ImageFit.Contain)
          Text($r('app.string.plvsa_more_microphone'))
            .fontSize(14)
            .fontColor('#F0F1F5')
        }
        .onClick(() => this.onClickControlMicrophone())
      }
      // 主讲权限
      if (this.linkmicState === PLVLinkMicState.Joined && this.viewer.viewerType === PLVUserType.USERTYPE_GUEST) {
        Row() {
          Image($r('app.media.plvsa_linkmic_speaker_icon'))
            .width(44)
            .height(44)
            .padding(10)
            .objectFit(ImageFit.Contain)
          Text(this.isSpeaker ? $r('app.string.plvsa_member_more_withdraw_speaker_permission') : $r('app.string.plvsa_member_more_grant_speaker_permission'))
            .fontSize(14)
            .fontColor('#F0F1F5')
        }
        .onClick(() => this.onClickSetSpeaker())
      }
      // 踢出
      if (!PLVSocketUserBean.isSpecialType(this.viewer.viewerType)) {
        Row() {
          Image($r('app.media.plvsa_member_kick_out_icon'))
            .width(44)
            .height(44)
            .padding(10)
            .objectFit(ImageFit.Contain)
          Text($r('app.string.plvsa_member_more_kick_out'))
            .fontSize(14)
            .fontColor('#F0F1F5')
        }
        .onClick(() => this.onClickKickViewer())
      }
      // 禁言
      if (!PLVSocketUserBean.isSpecialType(this.viewer.viewerType)) {
        Row() {
          Image($r('app.media.plvsa_chatroom_ban_chat_icon'))
            .width(44)
            .height(44)
            .padding(10)
            .objectFit(ImageFit.Contain)
          Text(this.isBan ? $r('app.string.plvsa_member_more_unban_chat') : $r('app.string.plvsa_member_more_ban_chat'))
            .fontSize(14)
            .fontColor('#F0F1F5')
        }
        .onClick(() => this.onClickBanViewer())
      }
    }
    .alignItems(HorizontalAlign.Start)
    .constraintSize({
      minWidth: 137
    })
    .padding({
      left: 14,
      right: 14,
      top: 10,
      bottom: 10
    })
  }

  private onClickLinkMicButton() {
    const isMyselfTeacher = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
    const isViewerUserTypeGuest = this.viewer.viewerType === PLVUserType.USERTYPE_GUEST
    const isViewerUserTypeViewer = this.viewer.viewerType === PLVUserType.USERTYPE_VIEWER
    const isLinkMicStrategyV2 = this.sdk.linkmicManager.isLinkMicStrategyV2.value ?? false
    const isChannelAllowInviteLinkMic = isLiteralTrue(this.sdk.channelData.liveDetail?.inviteAudioEnabled)
    const canInviteLinkMicV1 = !isLinkMicStrategyV2
      && isMyselfTeacher
      && (this.isChannelOpenLinkMic || isViewerUserTypeGuest || isViewerUserTypeViewer)
      && (isChannelAllowInviteLinkMic || isViewerUserTypeGuest || isViewerUserTypeViewer)
    const canInviteLinkMicV2 = isLinkMicStrategyV2
      && isMyselfTeacher
      && (isChannelAllowInviteLinkMic || isViewerUserTypeGuest || isViewerUserTypeViewer)
    const canInviteLinkMic = canInviteLinkMicV1 || canInviteLinkMicV2
    const notNeedAnswer = !isChannelAllowInviteLinkMic && (isViewerUserTypeGuest || isViewerUserTypeViewer)
    if (this.linkmicState === PLVLinkMicState.Requesting) {
      this.sdk.linkmicManager.acceptViewerLinkMicRequest(this.viewer.viewerId)
    } else if (this.linkmicState === PLVLinkMicState.Joined) {
      this.hangupLinkMicDialogController.open()
    } else if (canInviteLinkMic) {
      this.sdk.linkmicManager.inviteViewerLinkMic(this.viewer.viewerId, !notNeedAnswer)
    }
  }

  private onClickControlCamera() {
    this.sdk.linkmicManager.setViewerEnableCamera(this.viewer.viewerId, !this.isVideoEnable)
    this.morePopupVisible = false
  }

  private onClickControlMicrophone() {
    this.sdk.linkmicManager.setViewerEnableMicrophone(this.viewer.viewerId, !this.isAudioEnable)
    this.morePopupVisible = false
  }

  private onClickSetSpeaker() {
    if (this.isSpeaker) {
      this.sdk.linkmicManager.revokeSpeaker(this.viewer.viewerId)
    } else {
      this.sdk.linkmicManager.grantSpeaker(this.viewer.viewerId)
    }
    this.morePopupVisible = false
  }

  private onClickKickViewer() {
    this.kickViewerDialogController.open()
    this.morePopupVisible = false
  }

  private onClickBanViewer() {
    if (!this.isBan) {
      this.banViewerDialogController.open()
    } else {
      this.sdk.memberManager.banViewer(this.viewer.viewerId, false)
    }
    this.morePopupVisible = false
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}