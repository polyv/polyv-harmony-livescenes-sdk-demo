import {
  PLVBaseIdEvent,
  PLVChannelData,
  PLVChatQuoteDataBean,
  PLVCommonConstants,
  PLVLazyDataSource,
  PLVLiveSceneSDK
} from '@polyvharmony/live-scenes-sdk'
import { PLVSAChatInputEntryView } from './widget/PLVSAChatInputEntryView'
import { PLVSAChatInputView } from './widget/PLVSAChatInputView'
import { PLVSAChatListLayout } from './widget/PLVSAChatListLayout'
import { PLVSAEventHub } from './widget/PLVSAEventHub'
import { PLVSAGreetingView } from './widget/PLVSAGreetingView'
import { PLVSARewardBar } from './widget/PLVSARewardBar'

@Component
export struct PLVSAChatroomLayout {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  private chatListScroller: ListScroller = new ListScroller()
  @State private isQuizSelected: boolean = false
  @State private isShowChatInputLayout: boolean = false
  @State private isFocusModeOpen: boolean = false
  @State private isCloseRoom: boolean = false
  @State private quizMenu: undefined = undefined
  @State private fullChatListData: PLVLazyDataSource<PLVBaseIdEvent> = new PLVLazyDataSource()
  @State private quizListData: PLVLazyDataSource<PLVBaseIdEvent> = new PLVLazyDataSource()
  @State private reply: PLVChatQuoteDataBean | undefined = undefined

  aboutToAppear() {
    this.channelData = this.sdk?.channelData
    this.onReplyData()
  }

  build() {
    RelativeContainer() {
      PLVSAChatListLayout({
        isQuizSelected: this.isQuizSelected,
        isFocusModeOpen: this.isFocusModeOpen,
        quizMenu: this.quizMenu,
        fullChatListData: this.fullChatListData,
        chatListScroller: this.chatListScroller,
        quizListData: this.quizListData,
      })
        .id('plvsa_chatroom_list_layout')
        .width(244)
        .height(152)
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: 'plvsa_chatroom_input_entry_layout', align: VerticalAlign.Top }
        })
        .margin({
          left: 8,
          bottom: 16
        })

      PLVSAChatInputEntryView({
        isQuizSelected: this.isQuizSelected,
        isShowChatInputLayout: this.isShowChatInputLayout,
        quizMenu: this.quizMenu,
        isCloseRoom: this.isCloseRoom,
        isFocusModeOpen: this.isFocusModeOpen
      })
        .id('plvsa_chatroom_input_entry_layout')
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          left: 8,
          bottom: 8
        })

      PLVSAGreetingView()
        .id('plvsa_chatroom_greeting_layout')
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: 'plvsa_chatroom_list_layout', align: VerticalAlign.Top }
        })
        .margin({
          bottom: 16
        })

      if (this.isShowChatInputLayout) {
        PLVSAChatInputView({
          fullChatListData: this.fullChatListData,
          chatListScroller: this.chatListScroller,
          isShowChatInputLayout: this.isShowChatInputLayout,
          reply: this.reply
        })
          .id('plvsa_chatroom_input_layout')
          .width('100%')
          .alignRules({
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
          })
      }

      PLVSARewardBar()
        .id('plvsa_chatroom_reward_bar')
        .alignRules({
          bottom: { anchor: 'plvsa_chatroom_greeting_layout', align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({
          bottom: 16
        })
    }
  }

  onReplyData() {
    PLVSAEventHub.on('plvsa_chat_reply', (reply: PLVChatQuoteDataBean) => {
      this.reply = reply
      this.isShowChatInputLayout = true
    })
  }

  offReplyData() {
    PLVSAEventHub.off('plvsa_chat_reply')
  }

  aboutToDisappear(): void {
    this.offReplyData()
  }
}