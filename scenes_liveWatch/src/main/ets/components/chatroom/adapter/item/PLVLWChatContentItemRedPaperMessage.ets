import {
  PLVCommonConstants,
  PLVLiveSceneSDK,
  PLVRedPaperEvent,
  PLVRedPaperReceiveType,
  RedPaperReceiveTypeEvent
} from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatItemActionCallback,
  chatMessageAvatar,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemRedPaperMessage {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @ObjectLink message: PLVRedPaperEvent
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback

  aboutToAppear(): void {
    this.prepareRedPaperReceiveStatus()
  }

  private async prepareRedPaperReceiveStatus() {
    const receiveStatus = await this.sdk.redpackManager.getLocalCachedReceiveStatus(this.message.redpackId)
    this.message.receiveType = PLVRedPaperReceiveType.getValue(receiveStatus as RedPaperReceiveTypeEvent)
    this.sdk.redpackManager.cacheRedPaper(this.message)
  }

  build() {
    Column() {
      PLVLWChatContentItemSpeakContent({
        avatar: chatMessageAvatar(this.message.user?.getPic(), this.message.user?.userType),
        actor: this.message.user?.getActor(),
        actorColorForeground: $r('app.color.plvlw_chat_actor_foreground_color'),
        actorColorBackground: actorBackgroundColor(this.message.user?.userType),
        nick: this.message.user?.nick,
        nickColor: nickForegroundColor(this.message.user?.userType)
      })

      RelativeContainer() {
        Image($r("app.media.plvlw_chatroom_message_red_paper_icon"))
          .id('plvlw_chat_message_red_paper_icon')
          .width(36)
          .height(36)
          .alignRules({
            center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
            start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
          })

        Text(this.message.getTypeContent())
          .id('plvlw_chat_message_red_paper_blessing_message')
          .fontColor($r('app.color.plvlw_chat_content_red_paper_blessing_message_color'))
          .fontSize(12)
          .maxLines(1)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .ellipsisMode(EllipsisMode.END)
          .alignRules({
            top: { anchor: 'plvlw_chat_message_red_paper_icon', align: VerticalAlign.Top },
            start: { anchor: 'plvlw_chat_message_red_paper_icon', align: HorizontalAlign.End },
            end: { anchor: 'plvlw_chat_message_red_paper_receive_status_container', align: HorizontalAlign.Start }
          })
          .margin({
            left: 4
          })

        Text(this.message.getTypeName())
          .id('plvlw_chat_message_red_paper_type')
          .fontColor($r('app.color.plvlw_chat_content_red_paper_type_color'))
          .fontSize(12)
          .maxLines(1)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .ellipsisMode(EllipsisMode.END)
          .alignRules({
            bottom: { anchor: 'plvlw_chat_message_red_paper_icon', align: VerticalAlign.Bottom },
            start: { anchor: 'plvlw_chat_message_red_paper_icon', align: HorizontalAlign.End },
            end: { anchor: 'plvlw_chat_message_red_paper_receive_status_container', align: HorizontalAlign.Start }
          })
          .margin({
            left: 4
          })

        Stack() {
          if ([PLVRedPaperReceiveType.AVAILABLE, PLVRedPaperReceiveType.AVAILABLE_CLICKED]
            .includes(this.message.receiveType?.value ?? '')
          ) {
            Text($r('app.string.plvlw_chatroom_red_paper_receive'))
              .fontColor($r('app.color.plvlw_chat_content_red_paper_receive_button_text'))
              .fontSize(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(6)
              .padding({
                left: 6,
                right: 6
              })
          }
          if (this.message.receiveType?.value === PLVRedPaperReceiveType.RECEIVED) {
            Image($r('app.media.plvlw_chatroom_red_paper_status_received'))
              .width(52)
              .height(50)
          }
          if (this.message.receiveType?.value === PLVRedPaperReceiveType.RUN_OUT) {
            Image($r('app.media.plvlw_chatroom_red_paper_status_run_out'))
              .width(52)
              .height(50)
          }
          if (this.message.receiveType?.value === PLVRedPaperReceiveType.EXPIRED) {
            Image($r('app.media.plvlw_chatroom_red_paper_status_expired'))
              .width(52)
              .height(50)
          }
        }
        .id('plvlw_chat_message_red_paper_receive_status_container')
        .width(52)
        .height(PLVCommonConstants.FULL_PERCENT)
        .alignContent(Alignment.Center)
        .alignRules({
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
      }
      .width(204)
      .height(50)
      .borderRadius(8)
      .linearGradient({
        angle: 270,
        colors: [
          ['#FF5B59', 0],
          ['#FFAA5F', 1]
        ]
      })
      .opacity(this.viewBackgroundAlpha())
      .margin({
        top: 6
      })
      .onClick(() => {
        this.chatItemActionCallback.onClickRedPaper?.(this.message)
      })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 8,
      right: 8,
      top: 3,
      bottom: 3
    })
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .backgroundColor($r('app.color.plvlw_chat_content_item_background'))
  }

  private viewBackgroundAlpha() {
    if (this.message.receiveType?.value === PLVRedPaperReceiveType.AVAILABLE_CLICKED) {
      return 0.6
    } else {
      return 1
    }
  }
}