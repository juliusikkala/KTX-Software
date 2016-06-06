# This file is generated by gyp; do not edit.

TOOLSET := target
TARGET := appfwSDL
DEFS_Debug := \
	'-DDEBUG' \
	'-D_DEBUG'

# Flags passed to all source files.
CFLAGS_Debug := \
	-std=c++11 \
	-Og \
	-g

# Flags passed to only C files.
CFLAGS_C_Debug :=

# Flags passed to only C++ files.
CFLAGS_CC_Debug :=

INCS_Debug := \
	-I$(srcdir)/tests/loadtests/appfwSDL \
	-I$(srcdir)/other_include/SDL2 \
	-I$(srcdir)/other_include

DEFS_Release := \
	'-DNDEBUG'

# Flags passed to all source files.
CFLAGS_Release := \
	-std=c++11 \
	-O3

# Flags passed to only C files.
CFLAGS_C_Release :=

# Flags passed to only C++ files.
CFLAGS_CC_Release :=

INCS_Release := \
	-I$(srcdir)/tests/loadtests/appfwSDL \
	-I$(srcdir)/other_include/SDL2 \
	-I$(srcdir)/other_include

OBJS := \
	$(obj).target/$(TARGET)/tests/loadtests/appfwSDL/main.o \
	$(obj).target/$(TARGET)/tests/loadtests/appfwSDL/AppBaseSDL.o \
	$(obj).target/$(TARGET)/tests/loadtests/appfwSDL/GLAppSDL.o \
	$(obj).target/$(TARGET)/tests/loadtests/appfwSDL/SDL_vulkan.o \
	$(obj).target/$(TARGET)/tests/loadtests/appfwSDL/VkAppSDL.o

# Add to the list of files we specially track dependencies for.
all_deps += $(OBJS)

# Make sure our dependencies are built before any of us.
$(OBJS): | $(obj).target/libsdl.stamp

# CFLAGS et al overrides must be target-local.
# See "Target-specific Variable Values" in the GNU Make manual.
$(OBJS): TOOLSET := $(TOOLSET)
$(OBJS): GYP_CFLAGS := $(DEFS_$(BUILDTYPE)) $(INCS_$(BUILDTYPE))  $(CFLAGS_$(BUILDTYPE)) $(CFLAGS_C_$(BUILDTYPE))
$(OBJS): GYP_CXXFLAGS := $(DEFS_$(BUILDTYPE)) $(INCS_$(BUILDTYPE))  $(CFLAGS_$(BUILDTYPE)) $(CFLAGS_CC_$(BUILDTYPE))

# Suffix rules, putting all outputs into $(obj).

$(obj).$(TOOLSET)/$(TARGET)/%.o: $(srcdir)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)

$(obj).$(TOOLSET)/$(TARGET)/%.o: $(srcdir)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)

# Try building from generated source, too.

$(obj).$(TOOLSET)/$(TARGET)/%.o: $(obj).$(TOOLSET)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)

$(obj).$(TOOLSET)/$(TARGET)/%.o: $(obj).$(TOOLSET)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)

$(obj).$(TOOLSET)/$(TARGET)/%.o: $(obj)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)

$(obj).$(TOOLSET)/$(TARGET)/%.o: $(obj)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)

# End of this set of suffix rules
### Rules for final target.
LDFLAGS_Debug := \
	-g

LDFLAGS_Release :=

LIBS :=

$(obj).target/libappfwSDL.a: GYP_LDFLAGS := $(LDFLAGS_$(BUILDTYPE))
$(obj).target/libappfwSDL.a: LIBS := $(LIBS)
$(obj).target/libappfwSDL.a: TOOLSET := $(TOOLSET)
$(obj).target/libappfwSDL.a: $(OBJS) FORCE_DO_CMD
	$(call do_cmd,alink_thin)

all_deps += $(obj).target/libappfwSDL.a
# Add target alias
.PHONY: appfwSDL
appfwSDL: $(obj).target/libappfwSDL.a

# Add target alias to "all" target.
.PHONY: all
all: appfwSDL

