<script>
    import { router } from "@inertiajs/svelte";
    import { onMount, onDestroy, untrack } from "svelte";
    import DirectRoomItem from "./DirectRoomItem.svelte";
    import SharedRoomItem from "./SharedRoomItem.svelte";
    import DirectPlaceholder from "./DirectPlaceholder.svelte";
    import { SidebarStore } from "../stores/sidebar.svelte.js";

    import iconMessagesAdd from "images/messages-add.svg";
    import iconAdd from "images/add.svg";
    import iconMenu from "images/menu.svg";
    import iconSettings from "images/settings.svg";

    let {
        directMemberships = [],
        otherMemberships = [],
        directPlaceholderUsers = [],
        canCreateRooms = false,
        currentUser,
    } = $props();

    // Initialize store once
    const store = new SidebarStore();
    let connectedUserId = null;

    // Update store data when props change (don't reconnect)
    // Use untrack for store mutations to prevent effect loops
    $effect(() => {
        const directs = directMemberships;
        const others = otherMemberships;
        untrack(() => {
            store.init(directs, others);
        });
    });

    // Connect on mount
    onMount(() => {
        if (currentUser?.id) {
            connectedUserId = currentUser.id;
            store.connect(currentUser.id);
        }
    });

    onDestroy(() => {
        store.disconnect();
        connectedUserId = null;
    });

    function closeSidebarOnMobile() {
        if (window.innerWidth <= 100 * parseFloat(getComputedStyle(document.documentElement).fontSize.replace('px', '')) / 16 * 16) {
            const sidebar = document.getElementById("sidebar");
            if (sidebar) {
                sidebar.classList.remove("open");
            }
        }
    }

    function navigateToNewDirect() {
        closeSidebarOnMobile();
        router.visit("/rooms/directs/new");
    }

    function navigateToNewRoom() {
        closeSidebarOnMobile();
        router.visit("/rooms/opens/new");
    }

    function navigateToProfile() {
        closeSidebarOnMobile();
        router.visit("/users/me/profile");
    }

    function navigateToSettings() {
        closeSidebarOnMobile();
        router.visit("/account/edit");
    }

    function handleRoomCreated(e) {
        // Modal dispatches { room } on success. Close modal and navigate
        // to the returned room URL if provided by the server.
        showNewRoomModal = false;
        const room = e.detail?.room;
        const roomUrl = room?.room_url || room?.url || room?.room?.url;
        if (roomUrl) {
            router.visit(roomUrl);
        }
    }

    function toggleSidebar() {
        const sidebar = document.getElementById("sidebar");
        if (sidebar) {
            sidebar.classList.toggle("open");
        }
    }
</script>

<div class="sidebar__container overflow-y overflow-hide-scrollbar">
    <div id="direct_rooms_control">
        <div class="directs gap overflow-x overflow-hide-scrollbar">
            <a
                href="/rooms/directs/new"
                class="direct direct__new"
                onclick={(e) => {
                    e.preventDefault();
                    navigateToNewDirect();
                }}
            >
                <span class="avatar avatar--icon">
                    <img
                        src={iconMessagesAdd}
                        width="20"
                        height="20"
                        aria-hidden="true"
                        alt=""
                        class="colorize--black"
                    />
                </span>

                <span
                    class="direct__author flex max-width min-width border-radius pad-inline-half"
                >
                    <span class="for-screen-reader">New</span>
                    <span class="txt-small overflow-clip">Ping</span>
                </span>
            </a>

            {#each store.directMemberships as membership (membership.id)}
                <DirectRoomItem {membership} {currentUser} />
            {/each}

            {#each directPlaceholderUsers as user (user.id)}
                <DirectPlaceholder {user} />
            {/each}
        </div>
    </div>

    <div class="rooms position-relative flex flex-column gap">
        <div id="shared_rooms" class="flex flex-column gap">
            {#each store.otherMemberships as membership (membership.id)}
                <SharedRoomItem {membership} />
            {/each}
        </div>

        {#if canCreateRooms}
            <a
                href="/rooms/opens/new"
                class="rooms__new-btn btn room align-center gap txt-reversed"
                aria-label="New Chat Room"
                onclick={(e) => {
                    e.preventDefault();
                    navigateToNewRoom();
                }}
            >
                <img
                    src={iconAdd}
                    width="20"
                    height="20"
                    aria-hidden="true"
                    alt=""
                    style="view-transition-name: new-room"
                />
            </a>
        {/if}
    </div>

    <button class="btn sidebar__toggle" onclick={toggleSidebar}>
        <img src={iconMenu} width="20" height="20" aria-hidden="true" alt="" />
        <span class="for-screen-reader">Open menu</span>
    </button>
</div>

<div class="flex align-end sidebar__tools gap justify-end">
    <a
        href="/users/me/profile"
        class="btn avatar flex-item-no-shrink sidebar__tool"
        onclick={(e) => {
            e.preventDefault();
            navigateToProfile();
        }}
    >
        <img
            src={currentUser?.avatar_url}
            width="48"
            height="48"
            aria-hidden="true"
            alt=""
            style="view-transition-name: avatar-{currentUser?.id}"
        />
        <span class="for-screen-reader">My Settings</span>
    </a>

    <a
        href="/account/edit"
        class="btn align-center gap txt-reversed sidebar__tool"
        onclick={(e) => {
            e.preventDefault();
            navigateToSettings();
        }}
    >
        <img
            src={iconSettings}
            width="20"
            height="20"
            aria-hidden="true"
            alt=""
            style="view-transition-name: account-settings"
        />
        <span class="for-screen-reader">Account Settings</span>
    </a>
</div>
