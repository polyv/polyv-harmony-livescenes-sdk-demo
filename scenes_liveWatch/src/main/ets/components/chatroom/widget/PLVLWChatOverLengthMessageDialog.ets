import {
  PLVCommonConstants,
  PLVHistorySpeakEvent,
  PLVLiveSceneSDK,
  PLVSpeakEvent,
  PLVToastUtils,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk'
import { CustomDialogPayload, lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent
} from '../adapter/item/chat-content-item-common'

export class PLVLWChatOverLengthMessageDialogPayload {
  sdk: PLVLiveSceneSDK
  message: PLVSpeakEvent | PLVHistorySpeakEvent

  constructor(
    sdk: PLVLiveSceneSDK,
    message: PLVSpeakEvent | PLVHistorySpeakEvent
  ) {
    this.sdk = sdk
    this.message = message
  }
}

@Builder
export function PLVLWChatOverLengthMessageDialogBuilder(payload: CustomDialogPayload<PLVLWChatOverLengthMessageDialogPayload>) {
  PLVLWChatOverLengthMessageDialog({
    payload: payload
  })
}

@Component
struct PLVLWChatOverLengthMessageDialog {
  payload: CustomDialogPayload<PLVLWChatOverLengthMessageDialogPayload> = lateInit()
  private scroller: Scroller = new Scroller()
  @State private fullMessage: string = ''

  aboutToAppear(): void {
    this.payload.param?.message._overLengthFullMessage.get((fullMessage) => {
      this.fullMessage = fullMessage
    }, this.payload.param?.sdk?.chatroomManager)
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvlw_chat_full_text'))
        .id('plvlw_chat_over_length_title')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.plvlw_more_setting_action_popup_layout_title'))
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
        })
        .margin({
          top: 15
        })

      Divider()
        .id('plvlw_chat_over_length_divider')
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(1)
        .color('#EDEDEF')
        .alignRules({
          top: { anchor: 'plvlw_chat_over_length_title', align: VerticalAlign.Bottom }
        })
        .margin({
          top: 16
        })

      Scroll(this.scroller) {
        if (this.fullMessage) {
          PLVLWChatContentItemSpeakContent({
            actor: this.payload.param?.message.user?.getActor(),
            actorColorForeground: $r('app.color.plvlw_chat_actor_foreground_color'),
            actorColorBackground: actorBackgroundColor(this.payload.param?.message.user?.userType),
            nick: this.payload.param?.message.user?.nick,
            nickColor: nickForegroundColor(this.payload.param?.message.user?.userType, '#333333'),
            speakMessage: this.fullMessage,
            speakMessageColor: '#333333'
          })
        }
      }
      .scrollable(ScrollDirection.Vertical)
      .margin({
        top: 12,
        bottom: 24
      })
      .padding({
        left: 24,
        right: 24
      })
      .alignRules({
        top: { anchor: 'plvlw_chat_over_length_divider', align: VerticalAlign.Bottom },
        bottom: { anchor: 'plvlw_chat_over_length_copy_btn', align: VerticalAlign.Top }
      })

      Button($r('app.string.plvlw_chat_copy'))
        .id('plvlw_chat_over_length_copy_btn')
        .width(88)
        .height(28)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor($r('app.color.plvlw_theme_bg_blue'))
        .alignRules({
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          bottom: 36
        })
        .onClick(() => {
          PLVUtils.copyText(this.fullMessage).then(() => {
            PLVToastUtils.shortShow($r('app.string.plvlw_chat_copy_success'))
          })
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height('65%')
    .backgroundColor($r('app.color.plvlw_common_popup_background'))
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
  }
}