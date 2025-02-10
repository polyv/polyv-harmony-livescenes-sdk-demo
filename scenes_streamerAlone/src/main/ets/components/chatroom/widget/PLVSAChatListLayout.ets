import {
  ChannelMenusBean,
  PLVBaseIdEvent,
  PLVBaseIdUserEvent,
  PLVChannelData,
  PLVChatImgEvent,
  PLVCommonConstants,
  PLVEmotionEvent,
  PLVHistoryRedPaperEvent,
  PLVJSONUtils,
  PLVLazyDataSource,
  PLVLiveSceneSDK,
  PLVLocalQuizPromptEvent,
  PLVRedPaperEvent,
  PLVRedPaperForDelayEvent,
  PLVRedPaperReceiveType,
  PLVRedPaperResultEvent,
  PLVRemoveContentEvent,
  PLVRemoveHistoryEvent,
  PLVRewardEvent,
  PLVSimpleBuffer,
  PLVSocketEvent,
  PLVSocketOnEvent,
  PLVSocketUserBean,
  PLVSpeakEvent,
  PLVTAnswerEvent,
  PLVToastUtils,
  RedPaperReceiveTypeEvent
} from '@polyvharmony/live-scenes-sdk'
import { PLVSAChatListItem } from './PLVSAChatListItem'

const TAG = '[PLVSAChatListLayout]'

@Preview
@Component
export struct PLVSAChatListLayout {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Link isQuizSelected: boolean
  @Link @Watch('onFocusModeChanged') isFocusModeOpen: boolean
  // 聊天
  chatListScroller: ListScroller = new ListScroller()
  // 当前显示的数据列表
  @State chatListData: PLVLazyDataSource<PLVBaseIdEvent> = new PLVLazyDataSource()
  // 全部消息的数据列表
  @Link fullChatListData: PLVLazyDataSource<PLVBaseIdEvent>
  // 专注模式的数据列表(仅包括讲师类型、嘉宾类型、助教类型、管理员类型的信息)
  @State focusModeChatListData: PLVLazyDataSource<PLVBaseIdEvent> = new PLVLazyDataSource()
  @State isChatListRefreshing: boolean = true
  @State isChatListCanRefreshing: boolean = true
  @State isShowChatNewMessageTips: boolean = false
  getChatHistorySize: number = 10
  oldestChatHistoryTimestamp?: number
  oldestChatHistoryTimestampCount?: number
  socketMessageBuffer: PLVSimpleBuffer<PLVSocketEvent<string>> = new PLVSimpleBuffer()
  // 提问
  quizListScroller: ListScroller = new ListScroller()
  @Link quizListData: PLVLazyDataSource<PLVBaseIdEvent>
  @Link quizMenu: ChannelMenusBean | undefined
  @State isQuizListRefreshing: boolean = true
  @State isQuizListCanRefreshing: boolean = true
  @State isShowQuizNewMessageTips: boolean = false
  getQuizHistoryPage: number = 1
  getQuizHistorySize: number = 10

  aboutToAppear(): void {
    this.initData()
    this.onChatData()
  }

  aboutToDisappear(): void {
    this.socketMessageBuffer.release()
  }

  build() {
    Swiper() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Refresh({ refreshing: $$this.isChatListRefreshing }) {
          List({ space: 4, scroller: this.chatListScroller }) {
            LazyForEach(this.chatListData, (item: PLVBaseIdEvent) => {
              ListItem() {
                PLVSAChatListItem({ itemData: item })
              }
            }, (item: PLVBaseIdEvent) => item.getUniqueId())
          }
          .onScrollIndex((start, end) => {
            if (end == this.chatListData.totalCount() - 1) {
              this.isShowChatNewMessageTips = false
            }
          })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Fade)
          .cachedCount(5)
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(PLVCommonConstants.FULL_PERCENT)
        }
        .onRefreshing(() => {
          if (!this.isChatListCanRefreshing) {
            this.isChatListRefreshing = false
            return
          }
          this.getChatHistoryList()
        })

        if (this.isShowChatNewMessageTips) {
          this.newMessageTips(() => {
            this.isShowChatNewMessageTips = false
            this.chatListScroller.scrollEdge(Edge.Bottom)
          })
        }
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)

      if (this.quizMenu) {
        Stack({ alignContent: Alignment.BottomStart }) {
          Column() {
            Text($r('app.string.plvsa_chat_quiz_channel'))
              .height(28)
              .fontSize(14)
              .fontColor('#ffffff')
              .padding({ left: 10, right: 10 })
              .backgroundColor('#a6333333')
              .borderRadius(14)
              .margin({ bottom: 6 })

            Refresh({ refreshing: $$this.isQuizListRefreshing }) {
              List({ space: 4, scroller: this.quizListScroller }) {
                LazyForEach(this.quizListData, (item: PLVBaseIdEvent) => {
                  ListItem() {
                    PLVSAChatListItem({ itemData: item })
                  }
                }, (item: PLVBaseIdEvent) => item.getUniqueId())
              }
              .onScrollIndex((start, end) => {
                if (end == this.quizListData.totalCount() - 1) {
                  this.isShowQuizNewMessageTips = false
                }
              })
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Fade)
              .cachedCount(5)
              .width(PLVCommonConstants.FULL_PERCENT)
              .height(PLVCommonConstants.FULL_PERCENT)
            }
            .onRefreshing(() => {
              if (!this.isQuizListCanRefreshing) {
                this.isQuizListRefreshing = false
                return
              }
              this.getQuizHistoryList()
            })
            .height(0)
            .layoutWeight(1)
          }
          .alignItems(HorizontalAlign.Start)

          if (this.isShowQuizNewMessageTips) {
            this.newMessageTips(() => {
              this.isShowQuizNewMessageTips = false
              this.quizListScroller.scrollEdge(Edge.Bottom)
            })
          }
        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
      }
    }
    .width('100%')
    .height('100%')
    .loop(false)
    .autoPlay(false)
    .disableSwipe(true)
    .nestedScroll(SwiperNestedScrollMode.SELF_FIRST)
    .index(this.isQuizSelected ? 1 : 0)
    .onChange((index) => {
      this.isQuizSelected = index == 1
    })
    .indicator(
      this.quizMenu ? Indicator.dot()
        .left(0)
        .bottom(0)
        .itemWidth(38)
        .itemHeight(3)
        .selectedItemWidth(38)
        .selectedItemHeight(3)
        .color('#80ffffff')
        .selectedColor(Color.White) : false
    )
  }

  @Builder
  newMessageTips(onClick?: () => void) {
    Text($r("app.string.plvsa_chat_view_new_msg"))
      .backgroundColor('#F0F1F5')
      .borderRadius(30)
      .padding({
        left: 8,
        right: 8,
        top: 4,
        bottom: 4
      })
      .fontColor('#4399FF')
      .fontSize(14)
      .onClick(onClick)
  }

  initData() {
    this.chatListData.bindSource(this.fullChatListData)
  }

  onChatData() {
    this.socketMessageBuffer.observe((dataArr) => {
      let pushChatListDataArr: PLVBaseIdEvent[] = []
      dataArr.forEach((value) => {
        const data = value.message!
        const event = value.eventName!

        let pushChatListData: PLVBaseIdEvent | undefined = undefined
        let pushQuizListData: PLVBaseIdEvent | undefined = undefined
        switch (event) {
        // 发言
          case PLVSpeakEvent.EVENT: {
            const speakEvent = PLVJSONUtils.toFillData(PLVSpeakEvent, data)
            if (speakEvent) {
              // 过滤聊天室广播的自己的发言消息
              if (this.channelData?.viewerId != speakEvent.user?.userId) {
                pushChatListData = speakEvent
              }
            }
            break
          }
        // 图片
          case PLVChatImgEvent.EVENT: {
            const chatImgEvent = PLVJSONUtils.toFillData(PLVChatImgEvent, data)
            if (chatImgEvent) {
              // 过滤聊天室广播的自己的图片消息
              if (this.channelData?.viewerId != chatImgEvent.user?.userId) {
                pushChatListData = chatImgEvent
              }
            }
            break
          }
        // 打赏
          case PLVRewardEvent.EVENT: {
            const rewardEvent = PLVJSONUtils.toFillData(PLVRewardEvent, data)
            if (rewardEvent) {
              pushChatListData = rewardEvent
            }
            break
          }
        // 口令红包
          case PLVRedPaperEvent.EVENT: {
            const redPaperEvent = PLVJSONUtils.toFillData(PLVRedPaperEvent, data)
            if (redPaperEvent && redPaperEvent.isSupportType()) {
              pushChatListData = redPaperEvent
            }
            break
          }
          case PLVRedPaperResultEvent.EVENT: {
            const redPaperResult = PLVJSONUtils.json2Bean(PLVRedPaperResultEvent, data)
            if (redPaperResult) {
              this.sdk?.redpackManager.onRedPaperResultEvent(redPaperResult)
            }
            break
          }
        // 延迟红包
          case PLVRedPaperForDelayEvent.EVENT: {
            const redPaperForDelayEvent = PLVJSONUtils.json2Bean(PLVRedPaperForDelayEvent, data)
            if (redPaperForDelayEvent) {
              this.sdk?.redpackManager.notifyPostValue(redPaperForDelayEvent)
            }
            break
          }
        // 回答
          case PLVTAnswerEvent.EVENT: {
            const tAnswerEvent = PLVJSONUtils.toFillData(PLVTAnswerEvent, data)
            if (tAnswerEvent) {
              // 只取回答自己的消息
              if (this.channelData?.viewerId == tAnswerEvent.s_userId) {
                pushQuizListData = tAnswerEvent
              }
            }
            break
          }
        // 删除某条消息
          case PLVRemoveContentEvent.EVENT: {
            const removeContentEvent = PLVJSONUtils.json2Bean(PLVRemoveContentEvent, data)
            if (removeContentEvent?.id) {
              this.deleteDataToChatList(removeContentEvent.id)
            }
            break
          }
        // 清空所有消息
          case PLVRemoveHistoryEvent.EVENT: {
            this.clearDataToChatList()
            break
          }
          default:
            break;
        }
        if (pushChatListData) {
          pushChatListDataArr.push(pushChatListData)
        }
        if (pushQuizListData) {
          this.pushDataToQuizList(pushQuizListData)
        }
      })
      if (pushChatListDataArr.length > 0) {
        this.pushDataToChatList(...pushChatListDataArr)
      }
    })
    this.sdk?.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      // 缓冲500ms再更新一次数据，避免聊天信息刷得太频繁导致UI卡顿
      this.socketMessageBuffer.push({ message: data, eventName: event } as PLVSocketEvent<string>)
    }, this)
    this.sdk?.chatroomManager.onData(PLVSocketOnEvent.EMOTION, (data: string) => {
      // 个性表情
      const emotionEvent = PLVJSONUtils.toFillData(PLVEmotionEvent, data)
      if (emotionEvent) {
        this.pushDataToChatList(emotionEvent)
      }
    }, this)
  }

  getQuizHistoryList() {
    this.sdk?.chatroomManager.getQuizHistoryList(this.getQuizHistoryPage, this.getQuizHistorySize)
      .then((value) => {
        if (this.getQuizHistoryPage == 1 && value.list?.length == 0) {
          // 没有提问历史记录时，添加一条提问提示语
          const quizPromptEvent = new PLVLocalQuizPromptEvent()
          quizPromptEvent.prompt = this.quizMenu?.content || $r('app.string.plvsa_chat_quiz_default_tips')
          this.addDataToQuizList(quizPromptEvent)
        }
        if (value.list) {
          value.list.forEach((data, index) => {
            this.addDataToQuizList(data)
          })
          if (this.getQuizHistoryPage == 1) {
            this.quizListScroller.scrollEdge(Edge.Bottom)
          }
          this.getQuizHistoryPage++
          this.isQuizListRefreshing = false
          if (value.list.length < this.getQuizHistorySize) {
            this.isQuizListCanRefreshing = false
          }
        }
      })
      .catch((err: Error) => {
        this.isQuizListRefreshing = false
        PLVToastUtils.shortShow($r('app.string.plvsa_chat_toast_history_load_failed', `: ${err.message}`))
      })
  }

  getChatHistoryList() {
    this.sdk?.chatroomManager.getChatHistoryList(this.getChatHistorySize, this.oldestChatHistoryTimestamp, this.oldestChatHistoryTimestampCount)
      .then((values) => {
        const oldChatHistoryTimestamp = this.oldestChatHistoryTimestamp
        values.forEach((value, index) => {
          this.sdk?.chatroomManager.parseChatHistoryData(value, (data) => {
            const messageTimestamp = data['time'] as number
            if (!this.oldestChatHistoryTimestamp || messageTimestamp < this.oldestChatHistoryTimestamp) {
              this.oldestChatHistoryTimestamp = messageTimestamp
              this.oldestChatHistoryTimestampCount = 1
            } else if (this.oldestChatHistoryTimestamp == messageTimestamp && this.oldestChatHistoryTimestampCount) {
              this.oldestChatHistoryTimestampCount++
            }
            const baseIdEvent = data['data'] as PLVBaseIdEvent
            if (baseIdEvent) {
              this.addDataToChatList(baseIdEvent)
            }
            if (baseIdEvent instanceof PLVHistoryRedPaperEvent) {
              const historyRedPagerEvent = baseIdEvent as PLVHistoryRedPaperEvent
              const type = this.sdk?.redpackManager.geLocalCachedReceiveStatus(historyRedPagerEvent.redpackId)
                .then((value) => {
                  historyRedPagerEvent.receiveType = PLVRedPaperReceiveType.getValue(value as RedPaperReceiveTypeEvent)
                })

              this.sdk?.redpackManager.cacheRedPaper((baseIdEvent as PLVHistoryRedPaperEvent))
            }
          })
        })
        if (!oldChatHistoryTimestamp) {
          this.chatListScroller.scrollEdge(Edge.Bottom)
        }
        this.isChatListRefreshing = false
        if (values.length < this.getChatHistorySize) {
          this.isChatListCanRefreshing = false
        }
      })
      .catch((err: Error) => {
        this.isChatListRefreshing = false
        PLVToastUtils.shortShow($r('app.string.plvsa_chat_toast_history_load_failed', `: ${err.message}`))
      })
  }

  clearDataToChatList() {
    this.fullChatListData.clearData()
    this.focusModeChatListData.clearData()
  }

  deleteDataToChatList(id: string) {
    this.fullChatListData.dataArray.some((value, index) => {
      if (id === value.getUniqueId()) {
        this.fullChatListData.deleteData(index)
        return true
      }
      return false
    })
    this.focusModeChatListData.dataArray.some((value, index) => {
      if (id === value.getUniqueId()) {
        this.focusModeChatListData.deleteData(index)
        return true
      }
      return false
    })
  }

  addDataToChatList(data: PLVBaseIdEvent) {
    this.fullChatListData.addData(0, data)
    if (data instanceof PLVBaseIdUserEvent) {
      const isSpecialType = PLVSocketUserBean.isSpecialType((data as PLVBaseIdUserEvent).user?.userType)
      if (isSpecialType) {
        this.focusModeChatListData.addData(0, data)
      }
    }
  }

  pushDataToChatList(...data: PLVBaseIdEvent[]) {
    this.fullChatListData.pushData(...data)
    const specialTypeData: PLVBaseIdEvent[] = []
    data.forEach((value) => {
      if (value instanceof PLVBaseIdUserEvent) {
        const isSpecialType = PLVSocketUserBean.isSpecialType((value as PLVBaseIdUserEvent).user?.userType)
        if (isSpecialType) {
          specialTypeData.push(value)
        }
      }
    })
    this.focusModeChatListData.pushData(...specialTypeData)
    if (this.chatListScroller.isAtEnd()) {
      this.chatListScroller.scrollEdge(Edge.Bottom)
    } else {
      this.isShowChatNewMessageTips = true
    }
  }

  addDataToQuizList(data: PLVBaseIdEvent) {
    this.quizListData.addData(0, data)
  }

  pushDataToQuizList(data: PLVBaseIdEvent) {
    this.quizListData.pushData(data)
    if (this.quizListScroller.isAtEnd()) {
      this.quizListScroller.scrollEdge(Edge.Bottom)
    } else {
      this.isShowQuizNewMessageTips = true
    }
  }

  onFocusModeChanged() {
    this.chatListData.unbindSource()
    if (this.isFocusModeOpen) {
      this.chatListData.bindSource(this.focusModeChatListData)
      this.focusModeChatListData.reloadData()
    } else {
      this.chatListData.bindSource(this.fullChatListData)
      this.fullChatListData.reloadData()
    }
  }
}