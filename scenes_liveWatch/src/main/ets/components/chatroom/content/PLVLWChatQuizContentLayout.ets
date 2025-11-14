import {
  PLVBaseIdEvent,
  PLVChatImgEvent,
  PLVChatPlaybackDataVO,
  PLVCommonConstants,
  PLVEmotionEvent,
  PLVHistoryChatImgEvent,
  PLVHistorySpeakEvent,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVLocalQuizEvent,
  PLVLocalSpeakEvent,
  PLVSimpleBuffer,
  PLVSocketEvent,
  PLVSocketOnEvent,
  PLVSpeakEvent,
  PLVTAnswerEvent,
  PLVToastUtils,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk';
import {
  Dialogs,
  lateInit,
  MutableObserver,
  mutableStateOf,
  runCatching,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { ChatItemActionCallback } from '../adapter/item/chat-content-item-common';
import { PLVLWChatContentAdapter } from '../adapter/PLVLWChatContentAdapter';
import { PLVLWChatContentItem } from '../adapter/PLVLWChatContentItem';
import { PLVLWChatImageViewerBuilder, PLVLWChatImageViewerPayload } from '../widget/PLVLWChatImageViewer';

@Component
export struct PLVLWChatQuizContentLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @Provide('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback = new ChatItemActionCallback()
  private readonly messageBuffer = new PLVSimpleBuffer<PLVSocketEvent<string>>()
  private readonly adapter = new PLVLWChatContentAdapter()
  private readonly scroller = new Scroller()
  @State private isRefreshing: boolean = false
  @State private enableRefresh: boolean = true
  @State private unreadMessageCount: number = 0
  private readonly readLatestMessageIndex = mutableStateOf(0)
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.observeOnlineChatroomMessages()
    this.loadHistoryMessage()
    this.setupMessageCallback()
    watchStates(() => {
      const messageCount = (this.adapter.getChatMessagesState().value ?? []).length
      const lastMessageIndex = messageCount - 1
      const unreadMessageCount = lastMessageIndex - (this.readLatestMessageIndex.value ?? 0)
      this.layoutDataBus.chatTabStatus.mutate({
        quizUnreadMessageCount: unreadMessageCount
      })
      this.unreadMessageCount = unreadMessageCount
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      Row() {
        Image($r('app.media.plvlw_chatroom_quiz_icon'))
          .width(20)
          .height(20)
        Text($r('app.string.plvlw_chatroom_quiz_hint_title'))
          .fontSize(14)
          .fontColor($r('app.color.plvlw_chat_quiz_hint_text_title'))
          .margin({
            left: 4
          })
      }
      .id('plvlw_chat_content_quiz_hint_layout')
      .backgroundColor($r('app.color.plvlw_chat_quiz_hint_background'))
      .padding({
        left: 8,
        right: 8,
        top: 6,
        bottom: 6
      })
      .borderRadius(16)
      .alignRules({
        top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
        start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
      })

      Refresh({
        refreshing: this.isRefreshing
      }) {
        List({
          space: 4,
          scroller: this.scroller
        }) {
          ListItem() {
            Text($r('app.string.plvlw_chatroom_quiz_hint_content'))
              .fontSize(14)
              .fontColor($r('app.color.plvlw_chat_quiz_hint_text_content'))
              .backgroundColor($r('app.color.plvlw_chat_quiz_hint_background'))
              .borderRadius(16)
              .padding({
                left: 8,
                right: 8,
                top: 6,
                bottom: 6
              })
          }

          LazyForEach(
            this.adapter,
            (item: PLVBaseIdEvent, index: number) => {
              PLVLWChatContentItem({
                message: item
              })
            },
            (item: PLVBaseIdEvent) => item.getUniqueId()
          )
        }
        .scrollBar(BarState.Off)
        .onScrollIndex((start, end) => {
          this.readLatestMessageIndex.value = Math.max(this.readLatestMessageIndex.value ?? 0, end)
        })
      }
      .id('plvlw_chat_quiz_content')
      .pullToRefresh(this.enableRefresh)
      .onRefreshing(() => {
        this.loadHistoryMessage()
      })
      .alignRules({
        top: { anchor: 'plvlw_chat_content_quiz_hint_layout', align: VerticalAlign.Bottom },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
      })
      .margin({
        top: 8
      })

      Text() {
        Span($r('app.string.plvlw_chat_view_new_msg', this.unreadMessageCount.toString()))
          .fontSize(12)
          .fontColor($r('app.color.plvlw_chat_unread_message_text'))
        ImageSpan($r('app.media.plvlw_chatroom_new_message_icon'))
          .width(12)
          .height(12)
          .verticalAlign(ImageSpanAlignment.CENTER)
      }
      .id('plvlw_chat_live_unread_message_hint')
      .visibility(this.unreadMessageCount > 0 ? Visibility.Visible : Visibility.None)
      .backgroundColor($r('app.color.plvlw_chat_unread_message_background'))
      .borderRadius(16)
      .padding({
        left: 8,
        right: 8,
        top: 4,
        bottom: 4
      })
      .alignRules({
        start: { anchor: 'plvlw_chat_quiz_content', align: HorizontalAlign.Start },
        bottom: { anchor: 'plvlw_chat_quiz_content', align: VerticalAlign.Bottom }
      })
      .onClick(() => {
        this.scroller.scrollEdge(Edge.Bottom)
      })
    }
  }

  private observeOnlineChatroomMessages() {
    this.sdk.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      this.messageBuffer.push({
        eventName: event,
        message: data
      })
    }, this)
    this.layoutDataBus.onLocalChatEvent.observe((event) => {
      const isQuizEvent = event instanceof PLVLocalQuizEvent
      if (isQuizEvent) {
        this.appendOnlineMessage([event])
        setTimeout(() => {
          this.scroller.scrollEdge(Edge.Bottom)
        })
      }
    }).pushTo(this.observers)
    this.messageBuffer.observe((messageEvents: PLVSocketEvent<string>[]) => {
      this.processOnlineChatroomMessages(messageEvents)
    })
  }

  private processOnlineChatroomMessages(messageEvents: PLVSocketEvent<string>[]) {
    const result: PLVBaseIdEvent[] = []
    messageEvents.forEach((messageEvent) => {
      const event = messageEvent.eventName
      const data = messageEvent.message
      switch (event) {
        case PLVTAnswerEvent.EVENT: {
          const answerEvent = PLVJSONUtils.toFillData(PLVTAnswerEvent, data)
          if (answerEvent) {
            // 只取回答自己的消息
            if (this.sdk.channelData.viewerId == answerEvent.s_userId) {
              result.push(answerEvent);
            }
          }
          break;
        }
      }
    })

    this.appendOnlineMessage(result)
  }

  private appendOnlineMessage(messages: PLVBaseIdEvent[]) {
    const isScrollerAtBottom = this.scroller.isAtEnd();
    this.adapter.appendLast(messages)
    setTimeout(() => {
      if (isScrollerAtBottom) {
        this.scroller.scrollEdge(Edge.Bottom);
      }
    })
  }

  private async loadHistoryMessage() {
    if (this.isRefreshing) {
      return
    }
    this.isRefreshing = true
    const chatMessages = this.adapter.getChatMessages();
    const isFirstLoad = chatMessages.length === 0
    const cursor = this.retrieveHistoryMessageCursor(20)
    const page = cursor[0]
    const pageSize = cursor[1]
    const takeOldest = cursor[2]
    const result = await runCatching(this.sdk.chatroomManager.getQuizHistoryList(page, pageSize));
    if (result.success === false) {
      PLVToastUtils.shortShow(result.error.message);
      this.isRefreshing = false;
      return;
    }
    const historyMessages = result.data.list ?? []
    const takeMessages = historyMessages.reverse().slice(0, takeOldest)

    const isTop = this.scroller.currentOffset().yOffset === 0
    const isNoMoreHistory = historyMessages.length < pageSize
    this.readLatestMessageIndex.value += takeMessages.length
    this.adapter.appendFirst(takeMessages)
    setTimeout(() => {
      if (isFirstLoad) {
        this.scroller.scrollEdge(Edge.Bottom)
      } else if (isTop) {
        this.scroller.scrollEdge(Edge.Top)
      }
    })
    this.isRefreshing = false
    if (isNoMoreHistory) {
      this.enableRefresh = false
    }
  }

  private retrieveHistoryMessageCursor(pageSize: number): [number, number, number] {
    const chatMessages = this.adapter.getChatMessages();
    const messageSize = chatMessages.length
    const page = Math.floor(messageSize / pageSize) + 1
    const takeOldest = page * pageSize - messageSize
    return [page, pageSize, takeOldest]
  }

  private setupMessageCallback() {
    this.chatItemActionCallback.onClickCopy = (event: PLVSpeakEvent | PLVHistorySpeakEvent | PLVLocalSpeakEvent | PLVLocalQuizEvent | PLVTAnswerEvent) => {
      const runCopyText = async (text: string | undefined) => {
        await PLVUtils.copyText(text ?? '')
        PLVToastUtils.shortShow($r('app.string.plvlw_chat_copy_success'))
      }
      if (event instanceof PLVSpeakEvent) {
        runCopyText(event.values?.[0])
      } else if (event instanceof PLVHistorySpeakEvent) {
        runCopyText(event.content)
      } else if (event instanceof PLVLocalSpeakEvent) {
        runCopyText(event.speakMessage)
      } else if (event instanceof PLVLocalQuizEvent) {
        runCopyText(event.quizMessage)
      } else if (event instanceof PLVTAnswerEvent) {
        runCopyText(event.content)
      }
    }
    this.chatItemActionCallback.onClickImage = (event: PLVChatImgEvent | PLVHistoryChatImgEvent | PLVEmotionEvent | PLVTAnswerEvent | PLVChatPlaybackDataVO) => {
      Dialogs.showCustomDialog({
        context: this.getUIContext(),
        builder: PLVLWChatImageViewerBuilder,
        param: new PLVLWChatImageViewerPayload(this.sdk, event)
      })
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}