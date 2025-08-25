import {
  PLVCommonConstants,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVRedPaperForDelayEvent,
  PLVRedPaperResultEvent,
  PLVSocketOnEvent
} from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus'
import { PLVLWInteractSideBarLayout } from '../content/interactsidebar/PLVLWInteractSideBarLayout'
import { PLVLWProductPushCardLayout } from '../content/interactsidebar/product/PLVLWProductPushCardLayout'
import { PLVLWChatLiveContentLayout } from './content/PLVLWChatLiveContentLayout'
import { PLVLWChatQuizContentLayout } from './content/PLVLWChatQuizContentLayout'
import { PLVLWChatTopMessageBar } from './widget/PLVLWChatTopMessageBar'

@Component
export struct PLVLWChatroomLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private showChatLayout: boolean = false
  @State private showQuizLayout: boolean = false
  @State private tabSelectIndex: number = 0
  private readonly tabsController = new TabsController()
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.observeChatroomInteractMessage()
    this.layoutDataBus.chatTabStatus.observe(status => {
      this.showChatLayout = status.isEnableChatTab
      this.showQuizLayout = status.isEnableQuizTab
      this.tabsController.changeIndex(status.isSelectQuizTab ? 1 : 0)
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {

      PLVLWChatTopMessageBar()
        .id('plvlw_chat_top_message_bar')
        .margin({
          left: 12
        })
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })

      Tabs({
        controller: this.tabsController
      }) {
        if (this.showChatLayout) {
          TabContent() {
            PLVLWChatLiveContentLayout()
          }.clip(false)
        }

        if (this.showQuizLayout) {
          TabContent() {
            PLVLWChatQuizContentLayout()
          }.clip(false)
        }
      }
      .id('plvlw_chatroom_tabs_layout')
      .barHeight(0)
      .clip(false)
      .onChange(index => {
        this.tabSelectIndex = index
        this.layoutDataBus.chatTabStatus.mutate({
          isSelectQuizTab: index === 1
        })
      })
      .scrollable(this.showChatLayout && this.showQuizLayout)
      .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer, others: Array<GestureRecognizer>): GestureJudgeResult => { // 在识别器即将要成功时，根据当前组件状态，设置识别器使能状态
        if (current) {
          let target = current.getEventTargetInfo()
          if (target && current.isBuiltIn() && current.getType() == GestureControl.GestureType.PAN_GESTURE) {
            let panEvent = event as PanGestureEvent
            if (panEvent && panEvent.velocityX < 0 && this.tabSelectIndex === 1) { // 内层Tabs滑动到尽头
              return GestureJudgeResult.REJECT
            }
            if (panEvent && panEvent.velocityX > 0 && this.tabSelectIndex === 0) { // 内层Tabs滑动到开头
              return GestureJudgeResult.REJECT
            }
          }
        }
        return GestureJudgeResult.CONTINUE
      }, true)
      .alignRules({
        top: { anchor: 'plvlw_chat_top_message_bar', align: VerticalAlign.Bottom },
        bottom: { anchor: 'plvlw_chatroom_tabs_indicator', align: VerticalAlign.Top },
        left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
        right: { anchor: 'tabs_layout_barrier_right', align: HorizontalAlign.Start }
      })
      .margin({
        left: 12,
        right: 12,
        bottom: 8
      })

      Row({ space: 4 }) {
        Stack()
          .width(38)
          .height(3)
          .borderRadius(10)
          .backgroundColor(this.tabSelectIndex === 0 ? '#FFFFFF' : '#66FFFFFF')

        Stack()
          .width(38)
          .height(3)
          .borderRadius(10)
          .backgroundColor(this.tabSelectIndex === 1 ? '#FFFFFF' : '#66FFFFFF')
      }
      .id('plvlw_chatroom_tabs_indicator')
      .visibility(this.showChatLayout && this.showQuizLayout ? Visibility.Visible : Visibility.None)
      .alignRules({
        start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .margin({
        left: 12
      })

      PLVLWInteractSideBarLayout()
        .id('plvlw_interact_side_bar_layout')
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          bottom: { anchor: 'plvlw_product_push_card_layout', align: VerticalAlign.Top },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          right: 12
        })

      PLVLWProductPushCardLayout()
        .id('plvlw_product_push_card_layout')
        .alignRules({
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          right: 12
        })

      Stack()
        .id('guideline_tabs_layout_max_right')
        .width(0)
        .height(0)
        .alignRules({
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          right: 'calc(100% - 327vp)'
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .barrier([
      {
        id: 'tabs_layout_barrier_right',
        direction: BarrierDirection.LEFT,
        referencedId: ['guideline_tabs_layout_max_right', 'plvlw_interact_side_bar_layout', 'plvlw_product_push_card_layout']
      }
    ])
  }

  private observeChatroomInteractMessage() {
    this.sdk.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      switch (event) {
        case PLVRedPaperResultEvent.EVENT: {
          const redPaperResult = PLVJSONUtils.json2Bean(PLVRedPaperResultEvent, data)
          if (redPaperResult) {
            this.sdk.redpackManager.onRedPaperResultEvent(redPaperResult)
          }
          break;
        }
        case PLVRedPaperForDelayEvent.EVENT: {
          const redPaperForDelayEvent = PLVJSONUtils.json2Bean(PLVRedPaperForDelayEvent, data)
          if (redPaperForDelayEvent) {
            this.sdk?.redpackManager.notifyPostValue(redPaperForDelayEvent)
          }
          break;
        }
      }
    }, this)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

}