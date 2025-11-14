import {
  ChangePPTType,
  MenuType as ContentTabMenuType,
  IPLVCanReplyEvent,
  PLVBulletinEvent,
  PLVCallback,
  PLVChatImgEvent,
  PLVEmotionEvent,
  PLVInteractDataBean,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVLocalQuizEvent,
  PLVLocalSpeakEvent,
  PLVNewsPushEvent,
  PLVPPTStatus,
  PLVRemoveBulletinEvent,
  PLVRewardSettingVO,
  PLVSocketOnEvent,
  PLVSocketPushCardEvent,
  PLVSparseArray,
  PLVWebviewUpdateAppStatusVO
} from '@polyvharmony/live-scenes-sdk';
import { MutableEvent, mutableStateOf, Rect } from '@polyvharmony/media-player-sdk';

export class PLVLWLayoutDataBus {
  /**
   * 预加载的数据
   */
  readonly preload = new PreloadData()
  /**
   * 是否竖屏
   */
  readonly isPortrait = mutableStateOf(false)
  /**
   * 播放器区域位置
   */
  readonly playerLocation = mutableStateOf(new Rect())
  /**
   * 播放器是否铺满全屏
   */
  readonly playerFullscreen = mutableStateOf(false)
  /**
   * 播放器控制器状态
   */
  readonly playerControllerStatus = mutableStateOf(new PlayerControllerStatus())
  /**
   * 弹幕配置
   */
  readonly danmuSetting = mutableStateOf(new DanmuSetting())
  /**
   * 内容区tab状态
   */
  readonly contentTabMenuStatus = mutableStateOf(new ContentTabMenuStatus())
  /**
   * 聊天室tab状态
   */
  readonly chatTabStatus = mutableStateOf(new ChatTabStatus())
  /**
   * 聊天室输入框状态
   */
  readonly chatInputStatus = mutableStateOf(new ChatInputStatus())
  /**
   * 发送聊天室消息成功回调事件
   */
  readonly onLocalChatEvent = new MutableEvent<PLVLocalSpeakEvent | PLVEmotionEvent | PLVChatImgEvent | PLVLocalQuizEvent>()
  /**
   * 点赞事件 <likesCount>
   */
  readonly onClickLike = new MutableEvent<number>().async(false)
  /**
   * PPT是否在主屏
   */
  readonly isPPTToMainScreen = mutableStateOf(false)
  /**
   * PPT状态
   */
  readonly pptStatus = mutableStateOf<PLVPPTStatus>()
  /**
   * PPT切换
   */
  readonly onChangePPTPage = new MutableEvent<ChangePPTType>().async(false)
  /**
   * 顶层布局里的组件触摸事件拦截区域
   */
  readonly topLayerViewTouchArea = mutableStateOf<Rect>()
  /**
   * 底层布局里的组件触摸事件拦截区域
   */
  readonly bottomLayerViewTouchArea = mutableStateOf<Rect>()
  // <editor-fold defaultstate="collapsed" desc="返回监听拦截">
  private readonly backHandlers: PLVSparseArray<PLVCallback<void, boolean>> = new PLVSparseArray<PLVCallback<void, boolean>>()

  registerBackPressedHandler(handler: PLVCallback<void, boolean>, priority: number) {
    this.backHandlers.set(priority, handler)
  }

  unregisterBackPressedHandler(handler?: PLVCallback<void, boolean>) {
    this.backHandlers.forEachReverse((priority, h) => {
      if (h === handler) {
        this.backHandlers.delete(priority)
      }
    })
  }

  onBackPressed(): boolean {
    return this.backHandlers.someReverse((priority, handler) => {
      if (handler()) {
        return true
      }
      return false
    })
  }

  // </editor-fold>
}

export class PlayerControllerStatus {
  visible: boolean = true
  locked: boolean = false
}

export class DanmuSetting {
  show: boolean = true
}

export class ContentTabMenuStatus {
  selectTabType: ContentTabMenuType | undefined = undefined
}

export class ChatTabStatus {
  isEnableChatTab: boolean = false
  isEnableQuizTab: boolean = false
  isSelectQuizTab: boolean = false
  messageShowType: 'all' | 'only_teacher' = 'all'
  quizUnreadMessageCount: number = 0
}

export class ChatInputStatus {
  inputVisible: boolean = false
  emojiPanelVisible: boolean = false
  inputContent: string = ''
  replyMessage: IPLVCanReplyEvent | undefined = undefined
}

/**
 * 预加载数据
 *
 * 部分视图初始化时机较晚，这里提前存储数据以供使用
 */
class PreloadData {
  /**
   * 当前发布的公告
   */
  readonly bulletinEvent = mutableStateOf<PLVBulletinEvent | undefined>()
  /**
   * 聊天室关闭
   */
  readonly isChatroomClosed = mutableStateOf(false)
  /**
   * 互动应用功能
   */
  readonly interactDynamicActions = mutableStateOf<PLVWebviewUpdateAppStatusVO | undefined>()
  readonly interactStatusPendant = mutableStateOf<PLVWebviewUpdateAppStatusVO | undefined>()
  readonly interactData = mutableStateOf<PLVInteractDataBean | undefined>()
  /**
   * 打赏
   */
  readonly rewardSetting = mutableStateOf<PLVRewardSettingVO | undefined>()
  /**
   * 卡片推送
   */
  readonly cardPushEvent = mutableStateOf<PLVNewsPushEvent | undefined>()

  preload(sdk: PLVLiveSceneSDK) {
    this.observeChatroomMessage(sdk)
    this.observeInteractAppStatus(sdk)
    this.observeRewardSetting(sdk)
    this.observeCardPush(sdk)
  }

  private observeChatroomMessage(sdk: PLVLiveSceneSDK) {
    sdk.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      switch (event) {
        // 公告
        case PLVBulletinEvent.EVENT: {
          const bulletinEvent = PLVJSONUtils.json2Bean(PLVBulletinEvent, data)
          this.bulletinEvent.value = bulletinEvent
          break;
        }
      // 移除公告
        case PLVRemoveBulletinEvent.EVENT: {
          this.bulletinEvent.value = undefined
          break;
        }
      }
    }, this)

    sdk.chatroomManager.eventNotify.on('close_room', (isClose: boolean) => {
      this.isChatroomClosed.setValue(isClose)
    }, this)
  }

  private observeInteractAppStatus(sdk: PLVLiveSceneSDK) {
    sdk.interactManager.eventDataNotify.on('interact_data', (data: PLVInteractDataBean) => {
      this.interactData.value = data
    }, this)
    sdk.interactManager.interactStatusNotify.on('interact_status', (data: PLVWebviewUpdateAppStatusVO) => {
      if (data.event === 'UPDATE_CHAT_BUTTON') {
        this.interactDynamicActions.value = data
      }
      if (data.event === 'UPDATE_IAR_PENDANT') {
        this.interactStatusPendant.value = data
      }
    }, this)
  }

  private observeRewardSetting(sdk: PLVLiveSceneSDK) {
    sdk.rewardManager.eventNotify.on('reward_setting', (data: PLVRewardSettingVO) => {
      this.rewardSetting.value = data
    }, this)
  }

  private observeCardPush(sdk: PLVLiveSceneSDK) {
    sdk.pushcardManager.eventNotify.on('pushcard_data', (pushEvent: PLVNewsPushEvent) => {
      if (pushEvent.EVENT === PLVSocketPushCardEvent.NEWS_PUSH_START) {
        this.cardPushEvent.value = pushEvent
      }
      if (pushEvent.EVENT === PLVSocketPushCardEvent.NEWS_PUSH_CANCEL) {
        this.cardPushEvent.value = undefined
      }
    })
  }

}