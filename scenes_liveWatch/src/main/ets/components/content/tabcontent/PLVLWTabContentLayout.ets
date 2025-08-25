import {
  ChannelMenusBean,
  MenuType,
  PLVChannelData,
  PLVCommonConstants,
  PLVI18NDataMapper,
  PLVLiveScene,
  PLVLiveSceneSDK,
} from '@polyvharmony/live-scenes-sdk';
import { lateInit } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { DescTabData, PLVLWDescTabLayout } from './tab/PLVLWDescTabLayout';
import { PLVLWIFrameTabLayout } from './tab/PLVLWIFrameTabLayout';
import { PLVLWTextTabLayout } from './tab/PLVLWTextTabLayout';
import { PLVLWChatroomLayout } from '../../chatroom/PLVLWChatroomLayout';
import { PLVLWTuwenTabLayout } from './tab/PLVLWTuwenTabLayout';
import { PLVLWQATabLayout } from './tab/PLVLWQATabLayout';
import { PLVLWPreviousTabLayout, PreviousTabData } from './tab/PLVLWPreviousTabLayout';
import { ChapterTabData, PLVLWChapterTabLayout } from './tab/PLVLWChapterTabLayout';

@Preview
@Component
export struct PLVLWTabContentLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State tabDataBeanList: TabDataBean[] = []
  @State hasChatTab: boolean = false
  private liveScene: PLVLiveScene | undefined = this.channelData?.liveScene

  aboutToAppear(): void {
    this.initTabData()
    this.postCurrentSelectTab(0)
  }

  build() {
    Stack() {
      Tabs({ index: 0 }) {
        ForEach(this.tabDataBeanList, (item: TabDataBean, index: number) => {
          TabContent() {
            if (item.menuType === MenuType.CHAT) {
              PLVLWChatroomLayout()
            } else if (item.menuType == MenuType.DESC) {
              PLVLWDescTabLayout({ descTabData: new DescTabData(this.sdk, this.channelData, this.layoutDataBus) })
            } else if (item.menuType === MenuType.TEXT) {
              PLVLWTextTabLayout()
            } else if (item.menuType === MenuType.IFRAME) {
              PLVLWIFrameTabLayout()
            } else if (item.menuType === MenuType.TUWEN) {
              PLVLWTuwenTabLayout()
            } else if (item.menuType === MenuType.QA) {
              PLVLWQATabLayout()
            } else if (item.menuType === MenuType.PREVIOUS) {
              PLVLWPreviousTabLayout({ previousTabData: new PreviousTabData(this.sdk, this.channelData, this.layoutDataBus) })
            } else if (item.menuType === MenuType.CHAPTER) {
              PLVLWChapterTabLayout({ chapterTabData: new ChapterTabData(this.sdk, this.channelData, this.layoutDataBus) })
            }
          }
          .tabBar(new SubTabBarStyle(item.tabName)
            .padding({
              left: 28,
              right: 28,
              top: 0,
              bottom: 4
            })
            .indicator({
              color: $r('app.color.plvlw_theme_bg_blue'),
              height: 2,
              borderRadius: 2
            })
            .labelStyle({ unselectedColor: $r('app.color.plvlw_neutral_dark_white_60'), selectedColor: $r('app.color.plvlw_neutral_dark_white') }))
        })
      }
      .barHeight(PLVLiveScene.PORTRAIT_TEMPLATE === this.liveScene || (this.hasChatTab && this.tabDataBeanList.length == 1) ? 0 : 40)
      .barMode(BarMode.Scrollable, { nonScrollableLayoutStyle: LayoutStyle.ALWAYS_AVERAGE_SPLIT })
      .scrollable(this.tabDataBeanList.length > 1)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .hitTestBehavior(HitTestMode.Transparent)
      .gesture(SwipeGesture())
      .onChange(index => {
        this.postCurrentSelectTab(index)
      })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  private initTabData() {
    // 聊天tab
    let hasChatMenu = false
    let chatTabName: string | undefined
    let hasQuizMenu = false
    // 往期tab
    let previousTabName: ResourceStr | undefined = this.channelData?.getPreviousMenuName($r('app.string.plv_sdk_live_menu_name_previous'))
    let hasPreviousMenu = this.channelData?.hasPreviousMenu()
    let chapterTabName = $r('app.string.plv_sdk_live_menu_name_micro_chapter')
    let hasChapterMenu = this.channelData?.hasChapterMenu()
    this.channelData?.liveDetail?.channelMenus?.forEach((item?: ChannelMenusBean) => {
      switch (item?.menuType) {
        case MenuType.DESC:
          this.pushTab(item.menuType, item.name)
          break
        case MenuType.CHAT:
          hasChatMenu = "Y" === item.displayEnabled
          chatTabName = item.name
          break
        case MenuType.QUIZ:
          hasQuizMenu = true
          break
        case MenuType.TEXT:
          this.pushTab(item.menuType, item.name)
          break
        case MenuType.IFRAME:
          this.pushTab(item.menuType, item.name)
          break
        case MenuType.TUWEN:
          this.pushTab(item.menuType, item.name)
          break
        case MenuType.QA:
          this.pushTab(item.menuType, item.name)
          break
      }
    })
    if (hasChatMenu || hasQuizMenu) {
      this.pushChatTab(chatTabName, hasChatMenu, hasQuizMenu)
    }
    if (hasPreviousMenu) {
      this.pushTab(MenuType.PREVIOUS, previousTabName)
    }
    if (hasChapterMenu) {
      this.pushTab(MenuType.CHAPTER, chapterTabName)
    }
  }

  private pushChatTab(tabName?: string | Resource | undefined, hasChatMenu?: boolean, hasQuizMenu?: boolean) {
    this.hasChatTab = true
    let index = Math.min(1, this.tabDataBeanList.length)
    this.tabDataBeanList.splice(index, 0, new TabDataBean()
      .setMenuType(MenuType.CHAT)
      .setTabName(tabName))
    this.layoutDataBus.chatTabStatus.mutate({
      isEnableChatTab: hasChatMenu ?? false,
      isEnableQuizTab: hasQuizMenu ?? false
    })
  }

  private pushTab(menuType?: MenuType, tabName?: string | Resource | undefined) {
    if (this.liveScene === PLVLiveScene.LAND_TEMPLATE) {
      this.tabDataBeanList.push(new TabDataBean()
        .setMenuType(menuType)
        .setTabName(tabName))
    }
  }

  private postCurrentSelectTab(index: number) {
    this.layoutDataBus.contentTabMenuStatus.mutate({
      selectTabType: this.tabDataBeanList[index]?.menuType
    })
  }

}

class TabDataBean {
  menuType?: MenuType
  tabName?: string | Resource | undefined

  setMenuType(menuType?: MenuType) {
    this.menuType = menuType
    return this
  }

  setTabName(tabName?: string | Resource | undefined) {
    if (typeof tabName === 'string') {
      this.tabName = PLVI18NDataMapper.getMenuName(tabName)
    } else {
      this.tabName = tabName
    }
    return this
  }
}