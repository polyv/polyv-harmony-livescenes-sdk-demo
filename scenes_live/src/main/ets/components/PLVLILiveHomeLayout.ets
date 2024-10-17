import {
  ChannelMenusBean,
  GiftDetailDataBean,
  IPLVBackwardInterface,
  PLVBaseIdEvent,
  PLVCallback,
  PLVChannelData,
  PLVChatQuoteDataBean,
  PLVCommonConstants,
  PLVDeviceUtils,
  PLVLazyDataSource,
  PLVLiveSceneSDK,
  PLVProductDataBean,
  PLVRewardSettingVO,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk'
import { PLVLIWatchInfoView } from './liveroom/PLVLIWatchInfoView'
import { PLVLIChatInputEntryView } from './chatroom/PLVLIChatInputEntryView'
import { PLVLIChatInputView } from './chatroom/PLVLIChatInputView'
import { PLVLIChatListLayout } from './chatroom/PLVLIChatListLayout'
import { PLVLIBulletinView } from './liveroom/PLVLIBulletinView'
import { PLVLIMoreView } from './liveroom/PLVLIMoreView'
import { PLVLILikeIconView } from './chatroom/PLVLILikeIconView'
import { PLVLIGreetingView } from './chatroom/PLVLIGreetingView'
import { PLVLIRewardView } from './reward/PLVLIRewardView'
import { PLVLIProductView } from './product/PLVLIProductView'
import { PLVLIProductWebView, PLVProductWebViewController } from './product/PLVLIProductWebView'
import { PLVInteractWebViewController, PLVLIInteractWebView } from './interact/PLVLIInteractWebView'
import { PLVLIInteractEntranceView } from './interact/entrance/PLVLIInteractEntranceView'
import { PLVLICardPushView } from './interact/cardpush/PLVLICardPushView'
import { PLVLILotteryView } from './interact/lottery/PLVLILotteryView'
import { PLVLIRedpackView } from './chatroom/PLVLIRedpackView'
import { PLVLIEventHub } from '../common/PLVLIEventHub'
import { PLVLIToTopView } from './chatroom/PLVLIToTopView'

const TAG = '[PLVLILiveHomeLayout]'

@Preview
@Component
export struct PLVLILiveHomeLayout {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Link layoutController: PLVLiveHomeLayoutController
  @Link bulletinSrc: string | undefined
  chatListScroller: ListScroller = new ListScroller()
  // 全部消息的数据列表
  @State fullChatListData: PLVLazyDataSource<PLVBaseIdEvent> = new PLVLazyDataSource()
  quizListScroller: ListScroller = new ListScroller()
  @State quizListData: PLVLazyDataSource<PLVBaseIdEvent> = new PLVLazyDataSource()
  @State quizMenu: ChannelMenusBean | undefined = this.channelData?.getMenuQuizBean()
  @State isQuizSelected: boolean = false
  @State isShowChatInputLayout: boolean = false
  @State isCloseRoom: boolean = false
  @State isFocusModeOpen: boolean = false
  @State reply?: PLVChatQuoteDataBean = undefined
  @State rewardDataBeans?: GiftDetailDataBean[] = undefined
  @State rewardType?: string = undefined
  @State productDataBean?: PLVProductDataBean = this.sdk?.productManager.getData()
  @State productWebViewController: PLVProductWebViewController = new PLVProductWebViewController()
  @State interactWebViewController: PLVInteractWebViewController = new PLVInteractWebViewController()

  aboutToAppear(): void {
    this.initData()
    this.onProductData()
    this.onRewardData()
    this.onChatData()
    this.onReplyData()
    this.onDelayRedpackData()
  }

  aboutToDisappear(): void {
    this.offReplyData()
  }

  build() {
    RelativeContainer() {
      // <editor-fold defaultstate="collapsed" desc="观看信息View">
      PLVLIWatchInfoView()
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({ left: 16 })
        .id('watchInfoView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="公告View">
      PLVLIBulletinView({ bulletinSrc: this.bulletinSrc })
        .alignRules({
          top: { anchor: 'watchInfoView', align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({ left: 16, top: 16, right: 16 })
        .id('bulletinView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="互动入口View">
      PLVLIInteractEntranceView()
        .alignRules({
          top: { anchor: 'bulletinView', align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({ left: 16, top: 8 })
        .id('interactEntranceView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="评论上墙View">
      PLVLIToTopView()
        .alignRules({
          top: { anchor: 'interactEntranceView', align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({ top: 8 })
        .id('toTopView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="欢迎语View">
      PLVLIGreetingView()
        .alignRules({
          bottom: { anchor: 'chatListLayout', align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .id('greetingView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="聊天列表Layout">
      PLVLIChatListLayout({
        isQuizSelected: this.isQuizSelected,
        isFocusModeOpen: this.isFocusModeOpen,
        quizMenu: this.quizMenu,
        fullChatListData: this.fullChatListData,
        chatListScroller: this.chatListScroller,
        quizListData: this.quizListData,
        quizListScroller: this.quizListScroller
      })
        .alignRules({
          bottom: { anchor: 'chatInputEntryView', align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .id('chatListLayout')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="聊天输入入口View">
      PLVLIChatInputEntryView({
        isQuizSelected: this.isQuizSelected,
        isShowChatInputLayout: this.isShowChatInputLayout,
        quizMenu: this.quizMenu,
        isCloseRoom: this.isCloseRoom,
        isFocusModeOpen: this.isFocusModeOpen
      })
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({ left: 16 })
        .id('chatInputEntryView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="点赞View">
      PLVLILikeIconView()
        .alignRules({
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: 'moreView', align: VerticalAlign.Top }
        })
        .margin({ right: 16, bottom: 10 })
        .id('likeIconView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="商品View、打赏View">
      Row() {
        if (this.productDataBean?.isOpenProduct) {
          PLVLIProductView({
            productDataBean: this.productDataBean,
            productWebViewController: this.productWebViewController
          })
            .margin({ right: 12 })
            .id('productView')
        }
        if (this.rewardDataBeans) {
          PLVLIRewardView({
            rewardDataBeans: this.rewardDataBeans,
            rewardType: this.rewardType
          })
            .margin({ right: 12 })
            .id('rewardView')
        }
      }
      .alignRules({
        right: { anchor: 'moreView', align: HorizontalAlign.Start },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .id('rightBottomRow')

      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="更多View">
      PLVLIMoreView()
        .alignRules({
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({ right: 16 })
        .id('moreView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="聊天输入Layout">
      if (this.isShowChatInputLayout) {
        PLVLIChatInputView({
          isQuizSelected: this.isQuizSelected,
          isShowChatInputLayout: this.isShowChatInputLayout,
          fullChatListData: this.fullChatListData,
          chatListScroller: this.chatListScroller,
          quizListData: this.quizListData,
          quizListScroller: this.quizListScroller,
          isCloseRoom: this.isCloseRoom,
          isFocusModeOpen: this.isFocusModeOpen,
          quizMenu: this.quizMenu,
          reply: this.reply
        })
          .id('chatInputView')
      }
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="商品WebView">
      PLVLIProductWebView({
        viewController: this.productWebViewController
      })
        .zIndex(99)
        .id('productWebView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="互动挂件">

      Column({ space: 10 }) {
        PLVLIRedpackView()
        PLVLICardPushView()
        PLVLILotteryView()
      }
      .alignItems(HorizontalAlign.End)
      .alignRules({
        right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
        bottom: { anchor: "moreView", align: VerticalAlign.Top }
      })
      .margin({
        bottom: 72,
        right: 15
      })

      // </editor-fold>

      // <editor-fold defaultstate="collapsed" desc="互动WebView">
      PLVLIInteractWebView({
        viewController: this.interactWebViewController
      })
        .zIndex(100)
        .hitTestBehavior(this.interactWebViewController.isShow ? HitTestMode.Default : HitTestMode.Transparent)
        .id('interactWebView')
      // </editor-fold>

    }
    .padding({ top: 6, bottom: 6 + PLVDeviceUtils.getNavigationIndicatorHeight() })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  initData() {
    this.layoutController.productWebViewController = this.productWebViewController
    this.layoutController.interactWebViewController = this.interactWebViewController
  }

  onProductData() {
    this.sdk?.productManager.eventNotify.on('product_data', (value: PLVProductDataBean) => {
      this.productDataBean = value
    }, this)
  }

  onRewardData() {
    this.sdk?.rewardManager.eventNotify.on('reward_setting', (value: PLVRewardSettingVO) => {
      // 暂只支持礼物打赏(包含现金支付(仅免费)、积分支付类型)
      if (value.getDonateGiftEnabled()) {
        this.rewardType = value.giftDonate?.payWay
        if ('POINT' === value.giftDonate?.payWay) {
          this.rewardDataBeans = value.giftDonate.enabledPointPays
        } else if ('CASH' === value.giftDonate?.payWay) {
          this.rewardDataBeans = value.giftDonate.enabledCashPays
        }
      }
    }, this)
  }

  onChatData() {
    this.sdk?.chatroomManager.eventNotify.on('close_room', (value: boolean) => {
      this.isCloseRoom = value
      if (this.isCloseRoom && !this.isQuizSelected) {
        this.isShowChatInputLayout = false
      }
      PLVToastUtils.shortShow(value ? $r('app.string.plvli_chat_toast_chatroom_close') : $r('app.string.plvli_chat_toast_chatroom_open'))
    }, this)
    this.sdk?.chatroomManager.eventNotify.on('focus_mode_open', (value: boolean) => {
      this.isFocusModeOpen = value
      if (this.isFocusModeOpen && !this.isQuizSelected) {
        this.isShowChatInputLayout = false
      }
    }, this)
  }

  onReplyData() {
    PLVLIEventHub.on('plvli_chat_reply', (reply: PLVChatQuoteDataBean) => {
      this.reply = reply
      this.isShowChatInputLayout = true
    })
  }

  offReplyData() {
    PLVLIEventHub.off('plvli_chat_reply')
  }

  onDelayRedpackData() {
    this.sdk?.redpackManager.updateDelayRedpackStatus(this.sdk.channelData.loginChannelId)
  }
}

export class PLVLiveHomeLayoutController implements IPLVBackwardInterface {
  productWebViewController?: PLVProductWebViewController
  interactWebViewController?: PLVInteractWebViewController
  accessBackward: PLVCallback<void, boolean> = () => {
    return this.productWebViewController?.accessBackward() || this.interactWebViewController?.accessBackward() || false
  }
  backward: PLVCallback<void, void> = () => {
    if (this.productWebViewController?.accessBackward()) {
      this.productWebViewController.backward()
    }
    if (this.interactWebViewController?.accessBackward()) {
      this.interactWebViewController.isShow = false
      this.interactWebViewController.isShowInnerWeb = false

    }
  }
}