import { PLVChannelData, PLVCommonConstants, PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk';
import { lateInit, millis, MutableObserver, Throttle } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';

@Component
export struct PLVLWChatInputEntryLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @LocalStorageLink('channelData') channelData: PLVChannelData = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isChatroomClosed: boolean = false
  @State private isEnableQuizTab: boolean = false
  @State private isSelectQuizTab: boolean = false
  @State private quizHasNewMessage: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.chatTabStatus.observe(status => {
      this.isEnableQuizTab = status.isEnableQuizTab
      this.isSelectQuizTab = status.isSelectQuizTab
      this.quizHasNewMessage = status.quizUnreadMessageCount > 0
    }).pushTo(this.observers)
    this.layoutDataBus.preload.isChatroomClosed.observe(it => this.isChatroomClosed = it)
      .pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      Row() {
        if (this.isEnableQuizTab) {
          Image(this.isSelectQuizTab ? $r('app.media.plvlw_chatroom_quiz_icon_selected_light') : $r('app.media.plvlw_chatroom_quiz_icon_not_selected_light'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.onClickChangeChatSelectTab()
            })

          Blank().width(8)
          Divider()
            .vertical(true)
            .width(1)
            .height(14)
            .color('#28FFFFFF')
          Blank().width(8)
        }

        Text(this.getChatInputHint())
          .fontSize(14)
          .fontColor($r('app.color.plvlw_tool_bar_chat_input_text_hint'))
      }
      .alignRules({
        center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
        start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
        end: { anchor: 'plvlw_tool_bar_chat_emoji_iv', align: HorizontalAlign.Start }
      })
      .margin({
        left: 12,
        right: 8
      })

      if (this.isEnableQuizTab && !this.isSelectQuizTab && this.quizHasNewMessage) {
        Text($r('app.string.plvlw_tool_bar_chat_input_quiz_new_message'))
          .fontSize(8)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF5252')
          .padding({
            left: 4,
            right: 4,
            top: 2,
            bottom: 2
          })
          .borderRadius({
            topLeft: 6,
            bottomLeft: 1,
            topRight: 6,
            bottomRight: 6
          })
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
          })
          .margin({
            left: 18
          })
          .translate({
            y: -2
          })
      }

      Image($r('app.media.plvlw_tool_bar_chat_emoji_icon'))
        .id('plvlw_tool_bar_chat_emoji_iv')
        .width(20)
        .height(20)
        .alignRules({
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          right: 12
        })
        .onClick(() => {
          if (this.canInputMessage()) {
            this.layoutDataBus.chatInputStatus.mutate({
              inputVisible: true,
              emojiPanelVisible: true
            })
          }
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_tool_bar_chat_input_background'))
    .borderRadius(18)
    .onClick(() => {
      if (this.canInputMessage()) {
        this.layoutDataBus.chatInputStatus.mutate({
          inputVisible: true,
          emojiPanelVisible: false
        })
      }
    })
  }

  @Throttle(1, millis(300), () => {
  })
  private onClickChangeChatSelectTab() {
    this.layoutDataBus.chatTabStatus.mutate({
      isSelectQuizTab: !this.isSelectQuizTab
    })
  }

  private getChatInputHint() {
    if (this.isSelectQuizTab) {
      return $r('app.string.plvlw_chat_input_tips_quiz')
    }
    if (this.channelData.loginType == PLVLoginType.PLAYBACK) {
      return $r('app.string.plvlw_chat_input_tips_chatroom_close')
    }
    if (this.isChatroomClosed) {
      return $r('app.string.plvlw_chat_input_tips_chatroom_close')
    }
    return $r('app.string.plvlw_tool_bar_chat_input_hint')
  }

  private canInputMessage() {
    if (this.isSelectQuizTab) {
      return true
    }
    if (this.channelData.loginType == PLVLoginType.PLAYBACK) {
      return false
    }
    if (this.isChatroomClosed) {
      return false
    }
    return true
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}