import {
  IPLVCanOverLenEvent,
  IPLVCanReplyEvent,
  IPLVTimestampEvent,
  PLVBaseIdEvent,
  PLVBaseIdUserEvent,
  PLVChatImgEvent,
  PLVCommonConstants,
  PLVEmotionEvent,
  PLVHistoryChatImgEvent,
  PLVHistoryFileShareEvent,
  PLVHistorySpeakEvent,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVLocalQuizEvent,
  PLVLocalSpeakEvent,
  PLVRedPaperEvent,
  PLVRedPaperResultEvent,
  PLVRewardEvent,
  PLVSimpleBuffer,
  PLVSocketEvent,
  PLVSocketOnEvent,
  PLVSpeakEvent,
  PLVTAnswerEvent,
  PLVToastUtils,
  PLVUserType,
  PLVUtils,
  PLVWebUtils
} from '@polyvharmony/live-scenes-sdk';
import {
  Dialogs,
  extendNumber,
  lateInit,
  MutableObserver,
  mutableStateOf,
  promisify,
  runCatching,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { ChatItemActionCallback } from '../adapter/item/chat-content-item-common';
import { PLVLWChatContentAdapter } from '../adapter/PLVLWChatContentAdapter';
import { PLVLWChatContentItem } from '../adapter/PLVLWChatContentItem';
import { PLVLWChatImageViewerBuilder, PLVLWChatImageViewerPayload } from '../widget/PLVLWChatImageViewer';
import {
  PLVLWChatOverLengthMessageDialogBuilder,
  PLVLWChatOverLengthMessageDialogPayload
} from '../widget/PLVLWChatOverLengthMessageDialog';
import { PLVLWPinnedAnnouncementLayout } from '../widget/PLVLWPinnedAnnouncementLayout';
import { PLVLWRewardMessageLayout } from '../widget/PLVLWRewardMessageLayout';

// 有新消息到来时，限制最大保留的消息数量
const MAX_CACHE_CHAT_MESSAGE_COUNT: number = 3000

// 超过最大数量限制，允许溢出一部分再移除，避免频繁移除
const MAX_CACHE_MESSAGE_ALLOW_EXCEED_COUNT: number = 100

// 正在查看顶部n条消息时，不要自动移除消息
const AUTO_REMOVE_MESSAGE_LAST_VISIBLE_INDEX_AFTER: number = 300

@Component
export struct PLVLWChatLiveContentLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @Provide('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback = new ChatItemActionCallback()
  private readonly messageBuffer = new PLVSimpleBuffer<PLVSocketEvent<string>>()
  private readonly adapter = new PLVLWChatContentAdapter()
  private readonly scroller = new Scroller()
  @State private isRefreshing: boolean = false
  @State private enableRefresh: boolean = true
  @State private unreadMessageCount: number = 0
  private readonly readLatestMessageIndex = mutableStateOf(-1)
  private lastVisibleIndex: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.observeOnlineChatroomMessages()
    this.loadHistoryMessage()
    this.setupMessageCallback()

    watchStates(() => {
      const messageCount = (this.adapter.getChatMessagesState().value ?? []).length
      const lastMessageIndex = messageCount - 1
      this.unreadMessageCount = lastMessageIndex - (this.readLatestMessageIndex.value ?? -1)
    }).pushTo(this.observers)

    watchStates(() => {
      const messageShowType = this.layoutDataBus.chatTabStatus.value?.messageShowType ?? 'all'
      switch (messageShowType) {
        case 'all': {
          this.adapter.setMessageFilter(() => true)
          break;
        }
        case 'only_teacher': {
          this.adapter.setMessageFilter((message: PLVBaseIdEvent): boolean => {
            if (message instanceof PLVBaseIdUserEvent) {
              const user = message.user
              const isTeacher = user?.userType === PLVUserType.USERTYPE_TEACHER
              const isMe = user?.userId === this.sdk.channelData.viewerId
              return isTeacher || isMe
            }
            if (message instanceof PLVLocalSpeakEvent) {
              return true
            }
            return false
          })
          break;
        }
      }
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {

      PLVLWPinnedAnnouncementLayout()
        .id('plvlw_chat_pinned_announcement_layout')
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
          this.lastVisibleIndex = end
          this.readLatestMessageIndex.value = Math.max(this.readLatestMessageIndex.value ?? -1, end)
        })
      }
      .id('plvlw_chat_live_content')
      .pullToRefresh(this.enableRefresh)
      .onRefreshing(() => {
        this.loadHistoryMessage()
      })
      .alignRules({
        top: { anchor: 'plvlw_chat_pinned_announcement_layout', align: VerticalAlign.Bottom },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
      })

      PLVLWRewardMessageLayout()
        .id('plvlw_chat_reward_message_layout')
        .alignRules({
          top: { anchor: 'plvlw_chat_pinned_announcement_layout', align: VerticalAlign.Bottom },
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
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
        start: { anchor: 'plvlw_chat_live_content', align: HorizontalAlign.Start },
        bottom: { anchor: 'plvlw_chat_live_content', align: VerticalAlign.Bottom }
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
    this.sdk.chatroomManager.onData(PLVSocketOnEvent.EMOTION, (data: string) => {
      this.messageBuffer.push({
        eventName: PLVSocketOnEvent.EMOTION,
        message: data
      })
    }, this)
    this.layoutDataBus.onLocalChatEvent.observe((event) => {
      const isQuizEvent = event instanceof PLVLocalQuizEvent
      if (!isQuizEvent) {
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
        case PLVSpeakEvent.EVENT: {
          const speakEvent = PLVJSONUtils.toFillData(PLVSpeakEvent, data);
          if (speakEvent) {
            if (this.sdk.channelData.viewerId !== speakEvent.user?.userId) {
              result.push(speakEvent);
            }
          }
          break;
        }
        case PLVChatImgEvent.EVENT: {
          const chatImgEvent = PLVJSONUtils.toFillData(PLVChatImgEvent, data);
          if (chatImgEvent) {
            if (this.sdk.channelData.viewerId !== chatImgEvent.user?.userId) {
              result.push(chatImgEvent);
            }
          }
          break;
        }
        case PLVSocketOnEvent.EMOTION: {
          const emotionEvent = PLVJSONUtils.toFillData(PLVEmotionEvent, data);
          if (emotionEvent) {
            if (this.sdk.channelData.viewerId !== emotionEvent.user?.userId) {
              result.push(emotionEvent);
            }
          }
          break;
        }
        case PLVRewardEvent.EVENT: {
          const rewardEvent = PLVJSONUtils.toFillData(PLVRewardEvent, data);
          if (rewardEvent) {
            result.push(rewardEvent);
          }
          break;
        }
        case PLVRedPaperEvent.EVENT: {
          const redPaperEvent = PLVJSONUtils.toFillData(PLVRedPaperEvent, data);
          if (redPaperEvent && redPaperEvent.isSupportType()) {
            result.push(redPaperEvent);
          }
          break;
        }
        case PLVRedPaperResultEvent.EVENT: {
          if (data) {
            const redPaperResultEvent = PLVJSONUtils.json2Bean(PLVRedPaperResultEvent, data);
            if (redPaperResultEvent) {
              result.push(redPaperResultEvent);
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
    this.dropExceedMessages()
  }

  private async loadHistoryMessage() {
    if (this.isRefreshing) {
      return
    }
    this.isRefreshing = true
    const chatMessages = this.adapter.getChatMessages();
    const isFirstLoad = chatMessages.length === 0
    const loadHistoryCount = 20
    const cursor = this.retrieveHistoryMessageCursor()
    const lastTimestamp = cursor[0]
    const lastTimestampCount = cursor[1]
    const result = await runCatching(this.sdk.chatroomManager.getChatHistoryList(loadHistoryCount, lastTimestamp, lastTimestampCount));
    if (result.success === false) {
      PLVToastUtils.shortShow(result.error.message);
      this.isRefreshing = false;
      return;
    }
    const historyObjects = result.data;
    const historyMessages = (await Promise.all(
      historyObjects.map(async (historyObject) => {
        const parsedHistoryData = (await promisify(this.sdk.chatroomManager.parseChatHistoryData)(historyObject))[0]
        return parsedHistoryData['data'] as PLVBaseIdEvent
      })
    )).reverse()

    const isTop = this.scroller.currentOffset().yOffset === 0
    const isNoMoreHistory = historyObjects.length < loadHistoryCount
    this.readLatestMessageIndex.value += historyMessages.length
    this.adapter.appendFirst(historyMessages)
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

  private retrieveHistoryMessageCursor(): [number | undefined, number | undefined] {
    const chatMessages = this.adapter.getChatMessages();
    let lastTimestamp: number | undefined = undefined
    let count: number | undefined = undefined
    for (let chatMessage of chatMessages) {
      if ((chatMessage as object as IPLVTimestampEvent).getTime instanceof Function) {
        const timestamp = (chatMessage as object as IPLVTimestampEvent).getTime()
        if (lastTimestamp === undefined || lastTimestamp === 0) {
          lastTimestamp = timestamp
          count = 1
        } else if (lastTimestamp === timestamp) {
          count = (count ?? 1) + 1
        } else {
          break;
        }
      }
    }
    return [lastTimestamp, count]
  }

  private dropExceedMessages() {
    const currentCount = this.adapter.totalCount()
    if (currentCount < MAX_CACHE_CHAT_MESSAGE_COUNT + MAX_CACHE_MESSAGE_ALLOW_EXCEED_COUNT) {
      return
    }
    if (this.lastVisibleIndex < AUTO_REMOVE_MESSAGE_LAST_VISIBLE_INDEX_AFTER) {
      return
    }
    const dropCount = extendNumber(currentCount - MAX_CACHE_CHAT_MESSAGE_COUNT).coerceIn_ext(0, Number.MAX_SAFE_INTEGER)
    this.adapter.dropFirst(dropCount)
    this.readLatestMessageIndex.value -= dropCount
    if (dropCount > 0) {
      this.enableRefresh = true
    }
  }

  private setupMessageCallback() {
    this.chatItemActionCallback.onClickCopy = (event: PLVSpeakEvent | PLVHistorySpeakEvent | PLVLocalSpeakEvent | PLVLocalQuizEvent | PLVTAnswerEvent) => {
      const runCopyText = async (text: string | undefined) => {
        await PLVUtils.copyText(text ?? '')
        PLVToastUtils.shortShow($r('app.string.plvlw_chat_copy_success'))
      }
      if ((event as IPLVCanOverLenEvent)?.overLen && (event as IPLVCanOverLenEvent)._overLengthFullMessage) {
        (event as IPLVCanOverLenEvent)._overLengthFullMessage.get(async (text) => {
          await PLVUtils.copyText(text ?? '')
          PLVToastUtils.shortShow($r('app.string.plvlw_chat_copy_success'))
        }, this.sdk.chatroomManager)
      } else if (event instanceof PLVSpeakEvent) {
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
    this.chatItemActionCallback.onClickReply = (event: IPLVCanReplyEvent) => {
      this.layoutDataBus.chatInputStatus.mutate({
        replyMessage: undefined
      })
      this.layoutDataBus.chatInputStatus.mutate({
        inputVisible: true,
        replyMessage: event
      })
    }
    this.chatItemActionCallback.onClickImage = (event: PLVChatImgEvent | PLVHistoryChatImgEvent | PLVEmotionEvent | PLVTAnswerEvent) => {
      Dialogs.showCustomDialog({
        context: this.getUIContext(),
        builder: PLVLWChatImageViewerBuilder,
        param: new PLVLWChatImageViewerPayload(this.sdk, event)
      })
    }
    this.chatItemActionCallback.onClickFileShare = (event: PLVSpeakEvent | PLVHistoryFileShareEvent) => {
      const url = event.fileData?.url
      if (url) {
        PLVWebUtils.openWebLink(url)
      }
    }
    this.chatItemActionCallback.onClickRedPaper = (event: PLVRedPaperEvent) => {
      this.sdk.interactManager.receiveRedPaper(event)
    }
    this.chatItemActionCallback.onClickOverLengthShowFullMessage = (event: PLVSpeakEvent | PLVHistorySpeakEvent) => {
      Dialogs.showCustomDialog({
        context: this.getUIContext(),
        builder: PLVLWChatOverLengthMessageDialogBuilder,
        param: new PLVLWChatOverLengthMessageDialogPayload(this.sdk, event),
        options: {
          alignment: DialogAlignment.Bottom
        }
      })
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}